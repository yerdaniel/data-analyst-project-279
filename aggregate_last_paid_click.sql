WITH ranked_sessions AS (
    SELECT 
        s.visitor_id,
        s.visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        l.lead_id,
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
),
last_paid_clicks AS (
    SELECT 
        visitor_id,
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        lead_id,
        amount,
        closing_reason,
        status_id
    FROM ranked_sessions
    WHERE rn = 1
),
ads_costs AS (
    SELECT 
        campaign_date, 
        utm_source, 
        utm_medium, 
        utm_campaign, 
        SUM(daily_spent) AS daily_spent
    FROM (
        SELECT campaign_date, utm_source, utm_medium, utm_campaign, daily_spent FROM ya_ads
        UNION ALL
        SELECT campaign_date, utm_source, utm_medium, utm_campaign, daily_spent FROM vk_ads
    ) combined_ads
    GROUP BY campaign_date, utm_source, utm_medium, utm_campaign
)
SELECT 
    DATE(lpc.visit_date) AS visit_date,
    COUNT(DISTINCT lpc.visitor_id) AS visitors_count,
    lpc.utm_source,
    lpc.utm_medium,
    lpc.utm_campaign,
    MAX(a.daily_spent) AS total_cost,
    COUNT(DISTINCT lpc.lead_id) AS leads_count,
    COUNT(DISTINCT CASE WHEN lpc.closing_reason = 'Completado con éxito' OR lpc.status_id = 142 THEN lpc.lead_id END) AS purchases_count,
    SUM(CASE WHEN lpc.closing_reason = 'Completado con éxito' OR lpc.status_id = 142 THEN lpc.amount END) AS revenue
FROM last_paid_clicks lpc
LEFT JOIN ads_costs a 
    ON DATE(lpc.visit_date) = a.campaign_date 
    AND lpc.utm_source = a.utm_source 
    AND lpc.utm_medium = a.utm_medium 
    AND lpc.utm_campaign = a.utm_campaign
GROUP BY 
    DATE(lpc.visit_date),
    lpc.utm_source,
    lpc.utm_medium,
    lpc.utm_campaign
ORDER BY 
    revenue DESC NULLS LAST,
    visit_date ASC,
    visitors_count DESC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign asc;
