// Define Schema and setup
//
// Run with a Gremlin Console from the command line:
// $ bin/gremlin -i define_schema.groovy janusgraph-config.properties

janusGraphConfig = args[0]
println("Using JanusGraph Configuration {janusGraphConfig}")
graph = JanusGraphFactory.open(janusGraphConfig)

// Install Print Schema tool
//TODO: ADD THIS HERE


//-----------------------
// Load the Initial Schema
//-----------------------
mgmt = graph.openManagement()

// Define Vertex labels
Candidate = mgmt.makeVertexLabel("Candidate").make()
Contribution = mgmt.makeVertexLabel("Contribution").make()
IndividualContributor = mgmt.makeVertexLabel("IndividualContributor").make()
OrganizationContributor = mgmt.makeVertexLabel("OrganizationContributor").make()
State = mgmt.makeVertexLabel("State").make()
Zipcode = mgmt.makeVertexLabel("Zipcode").make()

// Define Edge labels - the relationships between Vertices
CONTRIBUTION_TO = mgmt.makeEdgeLabel("CONTRIBUTION_TO").multiplicity(MANY2ONE).make()
CONTRIBUTED = mgmt.makeEdgeLabel("CONTRIBUTED").multiplicity(SIMPLE).make()
STATE = mgmt.makeEdgeLabel("STATE").multiplicity(SIMPLE).make()
ZIP = mgmt.makeEdgeLabel("ZIP").multiplicity(SIMPLE).make()

// Define Vertex Property Keys

// Util Properties
type = mgmt.makePropertyKey("type").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()


// Candidate
name = mgmt.makePropertyKey("name").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()
filerCommitteeIdNumber = mgmt.makePropertyKey("filerCommitteeIdNumber").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()

mgmt.addProperties(Candidate, type, name, filerCommitteeIdNumber)


// Contribution
transactionId = mgmt.makePropertyKey("transactionId").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()
// TODO: Make Date
contributionDate = mgmt.makePropertyKey("contributionDate").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()
amount = mgmt.makePropertyKey("amount").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()
formType = mgmt.makePropertyKey("formType").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()
contributionType = mgmt.makePropertyKey("contributionType").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()
// TODO: Make Boolean
itemized = mgmt.makePropertyKey("itemized").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()
firstTimeDonor = mgmt.makePropertyKey("firstTimeDonor").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()
firstTimeItemized = mgmt.makePropertyKey("firstTimeItemized").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()

mgmt.addProperties(Contribution, type, transactionId, contributionDate,
                  amount, formType, contributionType, itemized,
                  firstTimeDonor, firstTimeItemized)


// IndividualContributor
firstName = mgmt.makePropertyKey("firstName").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()
lastName = mgmt.makePropertyKey("lastName").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()
middleName = mgmt.makePropertyKey("middleName").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()
prefix = mgmt.makePropertyKey("prefix").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()
suffix = mgmt.makePropertyKey("suffix").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()

mgmt.addProperties(IndividualContributor, type, firstName, lastName,
                   middleName, prefix, suffix)

// OrganizationContributor
organizationName = mgmt.makePropertyKey("organizationName").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()

mgmt.addProperties(OrganizationContributor, type, organizationName)


// State
postalAbbreviation = mgmt.makePropertyKey("postalAbbreviation").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()

mgmt.addProperties(State, type, postalAbbreviation)


// Zipcode
fiveDigit = mgmt.makePropertyKey("fiveDigit").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()
rawZip = mgmt.makePropertyKey("rawZip").
    dataType(String.class).cardinality(Cardinality.SINGLE).make()

mgmt.addProperties(Zipcode, type, fiveDigit, rawZip)


// Define connections as (EdgeLabel, VertexLabel out, VertexLabel in)
mgmt.addConnection(CONTRIBUTION_TO, Contribution, Candidate)
mgmt.addConnection(CONTRIBUTED, IndividualContributor, Contribution)
mgmt.addConnection(CONTRIBUTED, OrganizationContributor, Contribution)
mgmt.addConnection(STATE, OrganizationContributor, State)
mgmt.addConnection(STATE, IndividualContributor, State)
mgmt.addConnection(ZIP, OrganizationContributor, Zipcode)
mgmt.addConnection(ZIP, IndividualContributor, Zipcode)

mgmt.commit()

// Add basic indices
// TODO: Add indices
