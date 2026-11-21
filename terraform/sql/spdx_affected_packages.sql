SELECT
  t.account,
  t.resource,
  t.name AS resource_id,
  r.referencelocator AS cve,
  p.name,
  p.versioninfo
FROM spdx t
CROSS JOIN UNNEST(t.packages) AS up(p)
CROSS JOIN UNNEST(p.externalrefs) AS ur(r)
WHERE r.referencecategory = 'SECURITY'
  AND r.referencelocator IN (${target_cves})
ORDER BY t.account, t.resource, resource_id, cve
