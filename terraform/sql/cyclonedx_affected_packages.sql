SELECT
  t.account,
  t.resource,
  element_at(filter(t.metadata.properties, p -> p.name IN ('amazon:inspector:resource_arn', 'amazon:inspector:repository_arn')), 1).value AS resource_id,
  v.id AS cve,
  c.name,
  c.version,
  split_part(substr(c.purl, 5), '/', 1) AS purl_type
FROM cyclonedx t
CROSS JOIN UNNEST(t.vulnerabilities) AS uv(v)
CROSS JOIN UNNEST(v.affects) AS ua(a)
CROSS JOIN UNNEST(t.components) AS uc(c)
WHERE v.id IN (${target_cves})
  AND c.bom_ref = a.ref
ORDER BY t.account, t.resource, resource_id, v.id
