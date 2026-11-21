SELECT
  account,
  resource,
  element_at(filter(metadata.properties, p -> p.name IN ('amazon:inspector:resource_arn', 'amazon:inspector:repository_arn')), 1).value AS resource_id,
  coalesce(any_match(components, c -> regexp_like(c.name, '^(php[0-9.]*(-cli|-common)?|php/php)$')), false) AS has_php_runtime,
  cardinality(filter(components, c -> c.purl LIKE 'pkg:composer/%')) AS composer_packages,
  coalesce(any_match(vulnerabilities, v -> v.id IN (${target_cves})), false) AS hits_target_cve
FROM cyclonedx
ORDER BY account, resource, resource_id
