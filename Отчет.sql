USE CashOrders;
GO

IF OBJECT_ID('Reportt', 'V') IS NOT NULL 
    DROP VIEW Reportt;
GO

CREATE VIEW Reportt AS
SELECT 
    o1.title AS office_title,
    YEAR(o.created_at) AS year_num,
    MONTH(o.created_at) AS month_num,
    DATENAME(MONTH, o.created_at) + ' ' + CAST(YEAR(o.created_at) AS VARCHAR(4)) AS month_name,
    -- Главные показатели
    COUNT(o.id) AS total_orders,
    SUM(CASE WHEN os.name = 'Выдан' THEN 1 ELSE 0 END) AS issued_orders,
    SUM(CASE WHEN os.name IN ('Отменен', 'Отказан по лимиту', 'Отказан по остаткам') THEN 1 ELSE 0 END) AS cancelled_orders,
    SUM(o.total_sum) AS total_amount,
    AVG(o.total_sum) AS avg_order_amount,
    COUNT(ci.id) AS actual_issues, 
    CASE  -- Процент выполнения
        WHEN COUNT(o.id) = 0 THEN 0
        ELSE ROUND(100*1.0 * SUM(CASE WHEN os.name = 'Выдан' THEN 1 ELSE 0 END) / COUNT(o.id), 2)
    END AS issue_rate_pct
FROM Orders o
LEFT JOIN Offices o1 ON o.office_id = o1.id
LEFT JOIN OrderStatus os ON o.status_id = os.id
LEFT JOIN CashIssue ci ON o.id = ci.order_id
GROUP BY 
    o1.title,
    YEAR(o.created_at), 
    MONTH(o.created_at),
    DATENAME(MONTH, o.created_at) + ' ' + CAST(YEAR(o.created_at) AS VARCHAR(4))
HAVING COUNT(o.id) > 0  -- убираем пустые месяцы