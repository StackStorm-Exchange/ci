#!/usr/bin/env python
#
# A helper script to count content in a pack.
#
from __future__ import print_function

import argparse
import errno
import glob
import json
import os
from collections import OrderedDict
import yaml

RESOURCE_LOCATOR = {
    "sensors": {
        "path": ["sensors/*.yaml", "sensors/*.yml"],
        "key": "class_name",
    },
    "actions": {
        "path": ["actions/*.yaml", "actions/*.yml"],
        "key": "name",
    },
    "rules": {
        "path": ["rules/*.yaml", "rules/*.yml"],
        "key": "name",
    },
    "runners": {
        "path": ["runners/*/runner.yaml", "runners/*/runner.yml"],
        "key": "name",
    },
    "triggers": {
        "path": ["triggers/*.yaml", "triggers/*.yml"],
        "key": "name",
    },
    "aliases": {
        "path": ["aliases/*.yaml", "aliases/*.yml"],
        "key": "name",
    },
    "policies": {
        "path": ["policies/*.yaml", "policies/*.yml"],
        "key": "name",
    },
    "tests": {
        "key": "filename",
    },
}


def ordered_load(stream, Loader=yaml.SafeLoader, object_pairs_hook=OrderedDict):
    class OrderedLoader(Loader):  # pylint: disable=too-many-ancestors
        pass

    def construct_mapping(loader, node):
        loader.flatten_mapping(node)
        return object_pairs_hook(loader.construct_pairs(node))

    OrderedLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, construct_mapping)
    return yaml.load(stream, OrderedLoader)


def ordered_dump(data, stream=None, Dumper=yaml.Dumper, **kwds):
    class OrderedDumper(Dumper):  # pylint: disable=too-many-ancestors
        pass

    def _dict_representer(dumper, data):
        return dumper.represent_mapping(
            yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, data.items()
        )

    OrderedDumper.add_representer(OrderedDict, _dict_representer)
    return yaml.dump(data, stream, OrderedDumper, **kwds)


def get_pack_resources(pack_dir):
    resources = {}

    for resource, locator in RESOURCE_LOCATOR.items():

        resources[resource] = []
        matching_files = []

        if "path" not in locator:
            continue

        for path in locator["path"]:
            matching_files += glob.glob(os.path.join(pack_dir, path))

        for f in matching_files:
            with open(f, "r", encoding="utf-8") as fp:
                metadata = fp.read()
            metadata = yaml.safe_load(metadata)
            valid = True
            for validator in locator.get("validate", [locator.get("key")]):
                if validator not in metadata:
                    valid = False
            if valid:
                resources[resource].append(metadata)

    # Inaccurate, but for now we'll only need true/false.
    resources["tests"] = [
        {"filename": os.path.basename(name)}
        for name in glob.glob(os.path.join(pack_dir, "tests/*.py"))
    ]

    return resources


def return_resource_count(resources):
    result = {}
    for resource, entities in resources.items():
        if entities:
            key = RESOURCE_LOCATOR[resource]["key"]
            result[resource] = {
                "resources": sorted([item[key] for item in entities]),
                "count": len(entities),
            }
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Gather pack metadata")
    parser.add_argument("--input", help="Directory of the pack", required=True)
    parser.add_argument(
        "--output", help="Directory where the pack metadata should be saved", required=True
    )
    args = parser.parse_args()

    with open(os.path.join(args.input, "pack.yaml"), "r+", encoding="utf-8") as fp:
        meta = ordered_load(fp.read())

    content = get_pack_resources(args.input)
    meta["content"] = return_resource_count(content)

    for resource_type, resource_entities in content.items():
        key = RESOURCE_LOCATOR[resource_type]["key"]
        directory = os.path.join(args.output, resource_type)
        try:
            os.makedirs(directory)
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise
        for entity in resource_entities:
            with open(os.path.join(directory, f"{entity[key]}.json"), "w", encoding="utf-8") as fp:
                json.dump(entity, fp, indent=4, sort_keys=True, separators=(",", ": "))
                fp.write("\n")

    # Copy config schema
    try:
        with open(os.path.join(args.input, "config.schema.yaml"), "r+", encoding="utf-8") as fp:
            config = ordered_load(fp.read())

        with open(os.path.join(args.output, "config.schema.json"), "w", encoding="utf-8") as fp:
            json.dump(config, fp, indent=4, sort_keys=True, separators=(",", ": "))
            fp.write("\n")
    except IOError as e:
        print("Config file has not been copied:")
        print(e)
        print("skipping...")

    # Write out new pack.yaml with content count
    with open(os.path.join(args.output, "pack.yaml"), "w", encoding="utf-8") as fp:
        fp.write(ordered_dump(meta, Dumper=yaml.SafeDumper, default_flow_style=False))
