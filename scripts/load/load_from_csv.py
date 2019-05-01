#!/usr/bin/env python
"""Load FEC data from a csv file into JanusGraph."""

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import csv
from timeit import default_timer as timer

from ruamel.yaml import YAML

from gremlin_python.process.anonymous_traversal import traversal
from gremlin_python.driver.driver_remote_connection import DriverRemoteConnection
from gremlin_python.process.graph_traversal import __

DEFAULT_HOST = 'localhost'
DEFAULT_PORT = 8182

ROW_LIMIT = 1000


def get_traversal_source(host=None, port=None):
    """Get a Traversal Source from a Gremlin Server connection."""
    if not host:
        host = DEFAULT_HOST
    if not port:
        port = DEFAULT_PORT
    connection_string = 'ws://{0}:{1}/gremlin'.format(host, port)

    g = traversal().withRemote(DriverRemoteConnection(connection_string, 'g'))

    return g


def get_element_counts(expected_elements):
    """Queries the graph for counts of entities loaded."""
    start_time = timer()
    unique_vertices = set([vertex['vertex_label'] for vertex in expected_elements['vertices']])
    for vertex_label in unique_vertices: #expected_elements['vertices']:
        # vertex_label = vertex['vertex_label']
        print('{0} {1} vertices'.format(
                g.V().hasLabel(vertex_label).count().next(), vertex_label))

    unique_edges = set([edge['edge_label'] for edge in expected_elements['edges']])
    for edge_label in unique_edges: # expected_elements['edges']:
        # edge_label = edge['edge_label']
        print('{0} {1} edges'.format(
                g.E().hasLabel(edge_label).count().next(), edge_label))

    end_time = timer()
    count_time = end_time - start_time

    print('Count time: {0:.1f} sec'.format(count_time))


def get_lookup_values(record, lookup_properties):
    """Gets lookup values from a lookup_properties dictionary and a record."""
    lookup_values = {}
    for source_field, prop_key in lookup_properties.items():
        lookup_value = record[source_field]
        if not lookup_value or len(lookup_value) < 1:
            return None
        lookup_values[prop_key] = lookup_value

    return lookup_values



def insert_vertex(record, vertex_mapping, g):
    vertex_label = vertex_mapping['vertex_label']

    # Ensure all lookup values are present first
    lookup_values = get_lookup_values(record, vertex_mapping['lookup_properties'])
    if lookup_values is None:
        return

    # Setup traversals
    traversal = g.V().hasLabel(vertex_label)
    insertion_traversal = __.addV(vertex_label).property('type', vertex_label)

    for prop_key, lookup_value in lookup_values.items():
        traversal = traversal.has(prop_key, lookup_value)
        insertion_traversal = insertion_traversal.property(prop_key, lookup_value)

    # Add Vertex insertion partial traversal
    for source_field, prop_key in vertex_mapping['other_properties'].items():
        insertion_traversal = insertion_traversal.property(prop_key,
                                                           record[source_field])

    traversal.fold().coalesce(__.unfold(), insertion_traversal).next()


def insert_edge(record, edge_mapping, g):
    edge_label = edge_mapping['edge_label']
    # Simple logic, requiring that Vertices must exist before edge can be added.
    # Ensure all lookup values are present first
    out_lookup_values = get_lookup_values(record, edge_mapping['out_vertex']['lookup_properties'])
    in_lookup_values = get_lookup_values(record, edge_mapping['in_vertex']['lookup_properties'])
    if out_lookup_values is None or in_lookup_values is None:
        return


    traversal = g.V().hasLabel(edge_mapping['out_vertex']['vertex_label'])
    for prop_key, lookup_value in out_lookup_values.items():
        traversal = traversal.has(prop_key, lookup_value)

    traversal = traversal.as_('out').V().hasLabel(edge_mapping['in_vertex']['vertex_label'])
    for prop_key, lookup_value in in_lookup_values.items():
        traversal = traversal.has(prop_key, lookup_value)
    traversal.addE(edge_label).from_('out').next()


def load_from_csv(filename, record_mapping, g):
    """Loads vertices and edges from a csv file, based on a record mapping."""
    start_time = timer()
    with open(filename, 'r') as f:
        reader = csv.DictReader(f)
        row_count = 0

        for row in reader:
            # Insert graph entities from record.
            for vertex_mapping in record_mapping['vertices']:
                insert_vertex(row, vertex_mapping, g)

            # Count as we go?
            for edge_mapping in record_mapping['edges']:
                insert_edge(row, edge_mapping, g)

            row_count += 1

            if row_count >= ROW_LIMIT:
                break

            if row_count % 100 == 0:
                print("Loaded {0} rows".format(row_count))

    end_time = timer()
    load_time = end_time - start_time

    print('Load time: {0:.1f} sec'.format(load_time))
    print('({0:.1f} records / sec)'.format(row_count / load_time))


def get_record_mapping_from_yaml(filename):
    """Gets a record mapping dictionary from a YAML file."""
    with open(filename, 'r') as f:
        yaml = YAML(typ='safe')
        record_mapping = yaml.load(f)

    return record_mapping


if __name__ == '__main__':
    # TODO: Add argument for IP address
    g = get_traversal_source('localhost', 8182)

    # TODO: Arg arg for filename
    filename = '/Users/ryan/Projects/CampaignFinance/data/Contributions.csv'

    # TODO: Add arg for record mapping yaml filename
    record_mapping_yaml = '/Users/ryan/Projects/Enharmonic/janustools-py/resources/campaign_mapping.yaml'
    # TODO: Fix column names - reemove space...
    record_mapping = get_record_mapping_from_yaml(record_mapping_yaml)
    load_from_csv(filename, record_mapping, g)

    get_element_counts(record_mapping)
