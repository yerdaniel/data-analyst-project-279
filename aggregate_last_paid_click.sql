WITH last_paid_clicks AS (
    SELECT 
        s.visitor_id,
        s.visit_date,
        s.source,
        s.medium,
        s.campaign,
        ROW_NUMBER() OVER (PARTITION BY s.visitor_id ORDER BY s.visit_date DESC) AS rn
    FROM sessions s
    WHERE s.medium != 'organic' AND s.medium IS NOT NULL
)
SELECT 
    DATE(lpc.visit_date) AS visit_date,
    COUNT(DISTINCT lpc.visitor_id) AS visitors_count,
    lpc.source AS utm_source,
    lpc.medium AS utm_medium,
    lpc.campaign AS utm_campaign,
    COALESCE(SUM(a.daily_spent), 0) AS total_cost,
    COUNT(DISTINCT l.lead_id) AS leads_count,
    COUNT(DISTINCT CASE WHEN l.closing_reason = 'Completado con éxito' OR l.status_id = 142 THEN l.lead_id END) AS purchases_count,
    SUM(CASE WHEN l.closing_reason = 'Completado con éxito' OR l.status_id = 142 THEN l.amount END) AS revenue
FROM last_paid_clicks lpc
LEFT JOIN leads l ON lpc.visitor_id = l.visitor_id
LEFT JOIN (
    SELECT campaign_date, utm_source, utm_medium, utm_campaign, daily_spent FROM ya_ads
    UNION ALL
    SELECT campaign_date, utm_source, utm_medium, utm_campaign, daily_spent FROM vk_ads
) a ON DATE(lpc.visit_date) = a.campaign_date 
   AND lpc.source = a.utm_source 
   AND lpc.medium = a.utm_medium 
   AND lpc.campaign = a.utm_campaign
WHERE lpc.rn = 1
GROUP BY DATE(lpc.visit_date), lpc.source, lpc.medium, lpc.campaign
ORDER BY 
    revenue DESC NULLS LAST,
    visit_date ASC,
    visitors_count DESC,
    utm_source ASC, 
    utm_medium ASC, 
    utm_campaign asc;
