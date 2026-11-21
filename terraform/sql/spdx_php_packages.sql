SELECT
  t.account,
  t.resource,
  t.name AS resource_id,
  p.name,
  p.versioninfo,
  array_join(
    transform(
      filter(p.externalrefs, r -> r.referencecategory = 'SECURITY' AND r.referencelocator IN (${target_cves})),
      r -> r.referencelocator
    ),
    ', '
  ) AS target_cves
FROM spdx t
CROSS JOIN UNNEST(t.packages) AS u(p)
WHERE regexp_like(p.name, '^(php[0-9.]*(-cli|-common)?|php/php)$')
ORDER BY t.account, t.resource, resource_id, p.name
