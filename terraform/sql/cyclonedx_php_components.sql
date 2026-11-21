SELECT
  t.account,
  t.resource,
  element_at(filter(t.metadata.properties, p -> p.name IN ('amazon:inspector:resource_arn', 'amazon:inspector:repository_arn')), 1).value AS resource_id,
  c.name,
  c.version,
  c.purl,
  array_join(
    transform(
      filter(t.vulnerabilities, v -> v.id IN (${target_cves}) AND any_match(v.affects, a -> a.ref = c.bom_ref)),
      v -> v.id
    ),
    ', '
  ) AS target_cves
FROM cyclonedx t
CROSS JOIN UNNEST(t.components) AS u(c)
WHERE regexp_like(c.name, '^(php[0-9.]*(-cli|-common)?|php/php)$')
ORDER BY t.account, t.resource, resource_id, c.name
