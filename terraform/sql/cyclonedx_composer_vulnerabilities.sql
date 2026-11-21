SELECT
  c.name,
  c.version,
  array_join(array_agg(DISTINCT v.id), ', ') AS cves,
  array_join(array_agg(DISTINCT element_at(filter(t.metadata.properties, p -> p.name IN ('amazon:inspector:resource_arn', 'amazon:inspector:repository_arn')), 1).value), ', ') AS found_in
FROM cyclonedx t
CROSS JOIN UNNEST(t.vulnerabilities) AS uv(v)
CROSS JOIN UNNEST(v.affects) AS ua(a)
CROSS JOIN UNNEST(t.components) AS uc(c)
WHERE c.purl LIKE 'pkg:composer/%'
  AND c.bom_ref = a.ref
GROUP BY c.name, c.version
ORDER BY c.name, c.version
