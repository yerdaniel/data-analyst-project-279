SELECT 
    DATE(s.visit_date) AS visit_date,
    COUNT(DISTINCT s.visitor_id) AS visitors_count,
    s.source AS utm_source,
    s.medium AS utm_medium,
    s.campaign AS utm_campaign,
    COALESCE(SUM(a.daily_spent), 0) AS total_cost,
    COUNT(DISTINCT l.lead_id) AS leads_count,
    COUNT(DISTINCT CASE WHEN l.closing_reason = 'Completado con éxito' OR l.status_id = 142 THEN l.lead_id END) AS purchases_count,
    SUM(CASE WHEN l.closing_reason = 'Completado con éxito' OR l.status_id = 142 THEN l.amount END) AS revenue
FROM sessions s
LEFT JOIN leads l 
    ON s.visitor_id = l.visitor_id
LEFT JOIN (
    SELECT campaign_date, utm_source, utm_medium, utm_campaign, daily_spent FROM ya_ads
    UNION ALL
    SELECT campaign_date, utm_source, utm_medium, utm_campaign, daily_spent FROM vk_ads
) a 
    ON DATE(s.visit_date) = a.campaign_date AND s.source = a.utm_source AND s.medium = a.utm_medium AND s.campaign = a.utm_campaign
GROUP BY DATE(s.visit_date), s.source, s.medium, s.campaign
ORDER BY 
    revenue DESC NULLS LAST,
    visit_date ASC,
    visitors_count DESC,
    utm_source ASC, utm_medium ASC, utm_campaign ASC;




WITH ranked_sessions AS (
    SELECT 
        s.visitor_id,
        s.visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        ROW_NUMBER() OVER (
            PARTITION BY s.visitor_id 
            ORDER BY s.visit_date DESC
        ) as rn
    FROM sessions s
    LEFT JOIN leads l 
    	ON s.visitor_id = l.visitor_id AND l.created_at >= s.visit_date
    WHERE s.medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
)
SELECT 
    visitor_id,
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    lead_id,
    created_at,
    amount,
    closing_reason,
    status_id
FROM ranked_sessions
WHERE rn = 1
ORDER BY 
    amount DESC NULLS LAST,
    visit_date ASC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC;
