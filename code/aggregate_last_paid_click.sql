SELECT 
    DATE(s.visit_date) AS visit_date,
    COUNT(DISTINCT s.visitor_id) AS visitors_count,
    s.source AS utm_source,
    s.medium AS utm_medium,
    s.campaign AS utm_campaign,
    SUM(a.daily_spent) AS total_cost,
    COUNT(DISTINCT l.lead_id) AS leads_count,
    COUNT(DISTINCT CASE WHEN l.closing_reason = 'Completado con éxito' OR l.status_id = 142 THEN l.lead_id END) AS purchases_count,
    SUM(CASE WHEN l.closing_reason = 'Completado con éxito' OR l.status_id = 142 THEN l.amount END) AS revenue
FROM sessions s
LEFT JOIN leads l ON s.visitor_id = l.visitor_id
-- Cambiamos a INNER JOIN para quedarnos estrictamente con las visitas que tienen pauta pagada
JOIN (
    SELECT campaign_date, utm_source, utm_medium, utm_campaign, daily_spent FROM ya_ads
    UNION ALL
    SELECT campaign_date, utm_source, utm_medium, utm_campaign, daily_spent FROM vk_ads
) a ON DATE(s.visit_date) = a.campaign_date 
   AND s.source = a.utm_source 
   AND s.medium = a.utm_medium 
   AND s.campaign = a.utm_campaign
GROUP BY DATE(s.visit_date), s.source, s.medium, s.campaign
ORDER BY 
    revenue DESC NULLS LAST,
    visit_date ASC,
    visitors_count DESC,
    utm_source ASC, utm_medium ASC, utm_campaign ASC;