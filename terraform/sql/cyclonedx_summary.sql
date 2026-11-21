SELECT
  account,
  resource,
  element_at(filter(metadata.properties, p -> p.name IN ('amazon:inspector:resource_arn', 'amazon:inspector:repository_arn')), 1).value AS resource_id,
  any_match(components, c -> regexp_like(c.name, '^(php[0-9.]*(-cli|-common)?|php/php)$')) AS has_php_runtime,
  cardinality(filter(components, c -> c.purl LIKE 'pkg:composer/%')) AS composer_packages,
  any_match(vulnerabilities, v -> v.id IN (${target_cves})) AS hits_target_cve
FROM cyclonedx
ORDER BY account, resource, resource_id
