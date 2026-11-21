CREATE EXTERNAL TABLE cyclonedx (
  bomformat string,
  specversion string,
  metadata struct<
    timestamp: string,
    component: struct<name: string, type: string>,
    properties: array<struct<name: string, value: string>>
  >,
  components array<struct<
    bom_ref: string,
    type: string,
    name: string,
    version: string,
    purl: string
  >>,
  vulnerabilities array<struct<
    id: string,
    affects: array<struct<ref: string>>
  >>
)
PARTITIONED BY (account string, resource string)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES ('mapping.bom_ref' = 'bom-ref')
LOCATION '${location}'
