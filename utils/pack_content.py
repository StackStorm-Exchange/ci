#!/usr/bin/env python
#
# A helper script to count content in a pack.
#
import os
import glob
import yaml
from collections import OrderedDict

RESOURCE_LOCATOR = {
  'sensors': {
    'path': ['sensors/*.yaml', 'sensors/*.yml'],
    'validate': ['class_name']
  },
  'actions': {
    'path': ['actions/*.yaml', 'actions/*.yml'],
    'validate': ['name']
  },
  'rules': {
    'path': ['rules/*.yaml', 'rules/*.yml'],
    'validate': ['name']
  },
  'runners': {
    'path': ['runners/*/runner.yaml', 'runners/*/runner.yml'],
    'validate': ['name']
  },
  'triggers': {
    'path': ['triggers/*.yaml', 'triggers/*.yml'],
    'validate': ['name']
  },
  'aliases': {
    'path': ['aliases/*.yaml', 'aliases/*.yml'],
    'validate': ['name']
  },
  'policies': {
    'path': ['policies/*.yaml', 'policies/*.yml'],
    'validate': ['name']
  }
}


def ordered_load(stream, Loader=yaml.Loader, object_pairs_hook=OrderedDict):
    class OrderedLoader(Loader):
        pass

    def construct_mapping(loader, node):
        loader.flatten_mapping(node)
        return object_pairs_hook(loader.construct_pairs(node))
    OrderedLoader.add_constructor(
        yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG,
        construct_mapping)
    return yaml.load(stream, OrderedLoader)


def ordered_dump(data, stream=None, Dumper=yaml.Dumper, **kwds):
    class OrderedDumper(Dumper):
        pass

    def _dict_representer(dumper, data):
        return dumper.represent_mapping(
            yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG,
            data.items())
    OrderedDumper.add_representer(OrderedDict, _dict_representer)
    return yaml.dump(data, stream, OrderedDumper, **kwds)


def get_pack_resources(pack_dir):

    resources = {}

    for resource, locator in RESOURCE_LOCATOR.iteritems():

        resources[resource] = []
        matching_files = []

        for path in locator['path']:
            matching_files += glob.glob(os.path.join(pack_dir, path))

        for file in matching_files:
            with open(file, 'r') as fp:
                metadata = fp.read()
            metadata = yaml.safe_load(metadata)
            valid = True
            for validator in locator['validate']:
                if validator not in metadata:
                    valid = False
            if valid:
                resources[resource].append(metadata)

    # Inaccurate, but for now we'll only need true/false.
    resources['tests'] = glob.glob(os.path.join(pack_dir, 'tests/*.py'))

    return resources


def return_resource_count(resources):
    result = {}
    for k, v in resources.iteritems():
        if len(v):
            result[k] = {'count': len(v)}
    return result


if __name__ == '__main__':
    with open('pack.yaml', 'r+') as fp:
        meta = ordered_load(fp.read(), yaml.SafeLoader)

    content = get_pack_resources('.')
    meta['content'] = return_resource_count(content)

    # Write out new pack.yaml with content count
    with open('pack.yaml', 'w') as fp:
        fp.write(ordered_dump(meta, Dumper=yaml.SafeDumper,
                              default_flow_style=False))
