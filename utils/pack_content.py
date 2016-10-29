#!/usr/bin/env python
#
# A helper script to count content in a pack.
#
import os
import glob
import yaml

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
    return {k: {'count': len(v)} for k, v in resources.iteritems()}


if __name__ == '__main__':
    with open('pack.yaml', 'r+') as file:
        meta = yaml.load(file.read())
        content = get_pack_resources('.')
        meta['content'] = return_resource_count(content)
        file.seek(0)
        file.write(yaml.dump(meta))
        file.truncate()
