--ユーザー初回購入月からの継続率分析（コホート分析）

WITH user_first_order AS (
  -- ユーザーごとの「初めて購入した月（初回購入月)」
  SELECT
    user_id,
    MIN(FORMAT_TIMESTAMP('%Y-%m', created_at)) AS first_order_month
  FROM
    `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE
    status NOT IN ('Cancelled', 'Returned')
  GROUP BY
    user_id
),

order_months AS (
  --ユーザーごとの「すべての購入月」
  SELECT
    user_id,
    FORMAT_TIMESTAMP('%Y-%m', created_at) AS order_month
  FROM
    `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE
    status NOT IN ('Cancelled', 'Returned')
  GROUP BY
    user_id, order_month
),

cohort_sizes AS (
  -- 初回購入月（コホート）ごとの同期人数
  SELECT
    first_order_month,
    COUNT(DISTINCT user_id) AS cohort_size
  FROM
    user_first_order
  GROUP BY
    first_order_month
)

--初回購入月とその後の購入月を掛け合わせて、経過月ごとのリピート人数と率を計算
SELECT
  f.first_order_month AS cohort_month,
  s.cohort_size AS original_customer_count,
  -- 初回購入から何ヶ月経ったか（経過月数）を計算
  DATE_DIFF(
    DATE(PARSE_DATE('%Y-%m', o.order_month)), 
    DATE(PARSE_DATE('%Y-%m', f.first_order_month)), 
    MONTH
  ) AS months_lapsed,
  -- その月に戻ってきたリピーターの数
  COUNT(DISTINCT o.user_id) AS active_customer_count,
  -- 残存率（リピーター数 ÷ 同期の人数）を％で計算
  ROUND((COUNT(DISTINCT o.user_id) / s.cohort_size) * 100, 1) AS retention_rate
FROM
  user_first_order f
JOIN
  order_months o ON f.user_id = o.user_id
JOIN
  cohort_sizes s ON f.first_order_month = s.first_order_month
WHERE
  -- 2023年以降の比較的新しいデータに絞る
  f.first_order_month >= '2023-01'
GROUP BY
  cohort_month, cohort_size, months_lapsed
ORDER BY
  cohort_month ASC, months_lapsed ASC;
