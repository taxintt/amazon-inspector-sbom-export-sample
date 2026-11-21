CREATE EXTERNAL TABLE spdx (
  spdxid string,
  name string,
  spdxversion string,
  documentnamespace string,
  creationinfo struct<created: string, creators: array<string>>,
  packages array<struct<
    spdxid: string,
    name: string,
    versioninfo: string,
    externalrefs: array<struct<
      referencecategory: string,
      referencetype: string,
      referencelocator: string
    >>
  >>,
  relationships array<struct<
    spdxelementid: string,
    relationshiptype: string,
    relatedspdxelement: string
  >>
)
PARTITIONED BY (account string, resource string)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION '${location}'
