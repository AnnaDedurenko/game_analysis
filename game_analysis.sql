/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 

*/
-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков
-- 1.1. Доля платящих пользователей по всем данным:
SELECT COUNT(*) AS total_users,
SUM(CASE WHEN payer = 1 THEN 1 ELSE 0 END) AS paying_users,
SUM(CASE WHEN payer = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS fraction
FROM fantasy.users
-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь
SELECT  race,
		SUM(CASE WHEN payer = 1 THEN 1 ELSE 0 END) AS paying_users,
		COUNT(*) AS total_useres,
		SUM(CASE WHEN payer = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS fraction
FROM fantasy.users u 
JOIN fantasy.race r ON u.race_id = r.race_id 
GROUP BY race


-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь
SELECT COUNT(amount) AS count_am,
		SUM(amount) AS sum_am,
		MIN(amount) AS min_am,
		MAX(amount) AS max_am,
		AVG(amount) AS avg_am,
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount,
		STDDEV(amount) AS ct_otk
FROM fantasy.events e 		
-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь
WITH zero_amount AS (
		SELECT COUNT(*) AS count_null
		FROM fantasy.events e2 
		WHERE amount = 0
		),
total_amount AS (
		SELECT COUNT(*) AS count_total
		FROM fantasy.events e3 
		)
SELECT z.count_null,
		t.count_total,
		z.count_null * 1.0 / t.count_total AS fraction
FROM zero_amount z, total_amount t


SELECT 
    COUNT(*) AS zero_cost_purchases,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM events) AS zero_cost_percentage
FROM events
WHERE amount = 0;

-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
-- Напишите ваш запрос здесь
WITH payer_users AS (
	SELECT  id,
			COUNT(item_code) AS count_item,
			SUM(amount) AS sum_amount
	FROM fantasy.events e4  
	GROUP BY id
)
SELECT u.payer,
		COUNT(DISTINCT u.id) AS count_users,
		AVG(pu.count_item) AS avg_count_item,
		AVG(pu.sum_amount) AS avg_sum
FROM fantasy.users u 
LEFT JOIN payer_users pu ON u.id = pu.id
GROUP BY payer

-- 2.4: Популярные эпические предметы:
-- Напишите ваш запрос здесь

WITH total_sales_count AS (
    SELECT 
    	COUNT(*) AS total_transactions 
    	FROM fantasy.events 
    	WHERE amount > 0
),
total_players AS (
    SELECT 
    COUNT(DISTINCT id) AS total_players 
    FROM fantasy.events 
    WHERE amount > 0
),
item_sales AS (
    SELECT 
        e.item_code,
        i.game_items,
        COUNT(*) AS total_sales,
        COUNT(DISTINCT e.id) AS unique_buyers
    FROM fantasy.events e
    JOIN fantasy.items i ON e.item_code = i.item_code
    WHERE e.amount > 0
    GROUP BY e.item_code, i.game_items
) 
SELECT  i_s.item_code,
		i_s.game_items,
		i_s.total_sales * 100.0 / ts.total_transactions AS sales_percentage,
    	i_s.unique_buyers * 100.0 / tp.total_players AS player_percentage
FROM item_sales i_s 
CROSS JOIN total_sales_count ts
CROSS JOIN total_players tp
ORDER BY player_percentage DESC;

-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:
WITH payer_users AS (  
-- Подсчет общего количества игроков и платящих игроков по расе
    SELECT  
        r.race,
        r.race_id,
        COUNT(u.id) AS total_users,  -- Общее количество игроков по расе
        SUM(CASE WHEN u.payer = 1 THEN 1 ELSE 0 END) AS paying_users,  -- Количество платящих игроков
        SUM(CASE WHEN u.payer = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(u.id) AS fraction  -- Доля платящих игроков
    FROM fantasy.users u 
    JOIN fantasy.race r ON u.race_id = r.race_id 
    GROUP BY r.race, r.race_id
),
purchasing_players AS (
-- Количество игроков, совершивших хотя бы одну покупку
    SELECT 
        u.race_id,
        COUNT(DISTINCT e.id) AS purchasing_players
    FROM fantasy.users u
    JOIN fantasy.events e ON u.id = e.id
    WHERE e.amount > 0
    GROUP BY u.race_id
),
purchase_stats AS (
-- Подсчет покупок и общей суммы покупок по расе
    SELECT 
        u.race_id,
        COUNT(e.transaction_id) AS total_purchases,  -- Общее число покупок
        SUM(e.amount) AS total_amount_spent,  -- Суммарная стоимость покупок
        COUNT(e.transaction_id) * 1.0 / COUNT(DISTINCT e.id) AS avg_purchases_per_player,  -- Среднее количество покупок на игрока
        SUM(e.amount) * 1.0 / COUNT(DISTINCT e.id) AS avg_total_spent_per_player  -- Средние траты на игрока
    FROM fantasy.users u
    JOIN fantasy.events e ON u.id = e.id
    WHERE e.amount > 0
    GROUP BY u.race_id
)
SELECT 
    pu.race,  -- Название расы
    pu.total_users,  -- Общее количество зарегистрированных игроков
    pp.purchasing_players,  -- Количество игроков, которые совершали покупки
    pp.purchasing_players * 100.0 / NULLIF(pu.total_users, 0) AS purchasing_players_percentage,  -- Доля игроков, совершающих покупки
    pu.paying_users * 100.0 / NULLIF(pp.purchasing_players, 0) AS paying_players_percentage,  -- Доля платящих игроков среди покупающих
    ps.total_purchases,  -- Общее количество покупок
    ps.total_amount_spent,  -- Суммарная стоимость покупок
    ps.avg_purchases_per_player,  -- Среднее количество покупок на одного игрока
    ps.avg_total_spent_per_player  -- Средняя сумма трат на одного игрока
FROM payer_users pu
LEFT JOIN purchasing_players pp ON pu.race_id = pp.race_id
LEFT JOIN purchase_stats ps ON pu.race_id = ps.race_id
ORDER BY purchasing_players_percentage DESC;

-- Задача 2: Частота покупок
-- Напишите ваш запрос здесь
WITH filtered_events AS (
    -- Фильтруем только покупки эпических предметов и с ненулевой стоимостью
    SELECT  
        e.id AS user_id,
        e.date,
        e.amount 
    FROM fantasy.events e 
    JOIN fantasy.items i ON e.item_code = i.item_code  -- Фильтр по эпическим предметам
    WHERE e.amount > 0
),
count_interval AS (
    -- Считаем количество дней между покупками для каждого игрока
    SELECT 
        user_id,
        date,
        LAG(date) OVER (PARTITION BY user_id ORDER BY date) AS previous_date,
        DATE(date) - DATE(LAG(date) OVER (PARTITION BY user_id ORDER BY DATE(date))) AS days_between_purchase
    FROM filtered_events
),
payer_count AS (
    -- Считаем общее число покупок и средний интервал между покупками
    SELECT 
        user_id,
        COUNT(*) AS total_purchases,
        AVG(days_between_purchase) AS avg_days_between_purchases
    FROM count_interval
    GROUP BY user_id
    HAVING COUNT(*) >= 25 -- Учитываем только активных игроков
),
info_payer AS (
    -- Добавляем информацию о платящих игроках
    SELECT  
        pc.user_id,
        pc.total_purchases,
        pc.avg_days_between_purchases,
        u.payer
    FROM payer_count pc
    JOIN fantasy.users u ON pc.user_id = u.id
), 
rank_payer AS (
    -- Разделяем игроков на 3 группы по частоте покупок
    SELECT 
        user_id,
        total_purchases,
        avg_days_between_purchases,
        payer,
        NTILE(3) OVER (ORDER BY avg_days_between_purchases) AS purchase_frequency_group
    FROM info_payer
),
group_payer AS (
    -- Считаем метрики для каждой группы частоты покупок
    SELECT 
        purchase_frequency_group,
        COUNT(user_id) AS total_players,  -- Общее число игроков в группе
        SUM(CASE WHEN payer = 1 THEN 1 ELSE 0 END) AS paying_users,  -- Число платящих игроков
        AVG(total_purchases) AS avg_total_purchases,  -- Среднее число покупок
        AVG(avg_days_between_purchases) AS avg_days_between_purchases  -- Средний интервал между покупками
    FROM rank_payer
    GROUP BY purchase_frequency_group
)
-- Формируем итоговую таблицу
SELECT 
    CASE 
        WHEN purchase_frequency_group = 1 THEN 'высокая частота'
        WHEN purchase_frequency_group = 2 THEN 'умеренная частота'
        WHEN purchase_frequency_group = 3 THEN 'низкая частота'
    END AS purchase_frequency_group,
    total_players,
    paying_users,
    CASE 
        WHEN total_players = 0 THEN NULL
        ELSE paying_users * 1.0 / total_players
    END AS paying_fraction,
    avg_total_purchases,
    avg_days_between_purchases
FROM group_payer 
ORDER BY purchase_frequency_group;





