-- 02_seed.sql
-- Dummy data: 15 customers across all plan types, 33 page views.
-- Page view times are relative to NOW() so the "last 7 days" filter
-- always has data to work with. Re-run 01 + 02 right before a demo.

INSERT INTO customers (id, email, first_name, last_name, plan_type, candidate) VALUES
    (12345, 'testuser1@gmail.com',  'Jane',   'Doe',     'pro',        'John'),
    (12346, 'testuser2@gmail.com',  'Marcus', 'Lee',     'free',       'John'),
    (12347, 'testuser3@gmail.com',  'Priya',  'Shah',    'basic',      'John'),
    (12348, 'testuser4@gmail.com',  'Tom',    'Becker',  'enterprise', 'John'),
    (12349, 'testuser5@gmail.com',  'Ana',    'Ruiz',    'pro',        'John'),
    (12350, 'testuser6@gmail.com',  'Kevin',  'Park',    'free',       'John'),
    (12351, 'testuser7@gmail.com',  'Laura',  'Chen',    'pro',        'John'),
    (12352, 'testuser8@gmail.com',  'Omar',   'Haddad',  'basic',      'John'),
    (12353, 'testuser9@gmail.com',  'Sofia',  'Rossi',   'enterprise', 'John'),
    (12354, 'testuser10@gmail.com', 'Ben',    'Carter',  'pro',        'John'),
    (12355, 'testuser11@gmail.com', 'Emily',  'Nguyen',  'free',       'John'),
    (12356, 'testuser12@gmail.com', 'David',  'Kim',     'basic',      'John'),
    (12357, 'testuser13@gmail.com', 'Grace',  'Hall',    'pro',        'John'),
    (12358, 'testuser14@gmail.com', 'Luis',   'Moreno',  'enterprise', 'John'),
    (12359, 'testuser15@gmail.com', 'Hannah', 'Wright',  'basic',      'John');

-- Each row stores how long ago the view happened ("ago");
-- event_time = now (rounded to the second) minus that amount.
INSERT INTO page_views (id, user_id, page, device, browser, location, event_time)
SELECT id, user_id, page, device, browser, location,
       date_trunc('second', NOW()) - ago::interval
FROM (VALUES
    (100001, 12345, 'Pricing',   'MacBook Pro',     'Chrome',  'Los Angeles, CA',   '2 days 5 hours'),
    (100002, 12345, 'Settings',  'MacBook Pro',     'Chrome',  'Los Angeles, CA',   '1 day 3 hours'),
    (100003, 12345, 'Home page', 'iPhone 15',       'Safari',  'Los Angeles, CA',   '3 hours'),
    (100004, 12349, 'Pricing',   'Dell XPS 13',     'Firefox', 'Austin, TX',        '3 days 1 hour'),
    (100005, 12349, 'Dashboard', 'Dell XPS 13',     'Firefox', 'Austin, TX',        '6 days'),
    (100006, 12351, 'Settings',  'Pixel 8',         'Chrome',  'Seattle, WA',       '10 days'),
    (100007, 12351, 'Home page', 'Pixel 8',         'Chrome',  'Seattle, WA',       '1 day'),
    (100008, 12354, 'Settings',  'Surface Laptop',  'Edge',    'Chicago, IL',       '4 days 6 hours'),
    (100009, 12354, 'Pricing',   'Surface Laptop',  'Edge',    'Chicago, IL',       '20 days'),
    (100010, 12357, 'Dashboard', 'iPad Air',        'Safari',  'Denver, CO',        '2 days'),
    (100011, 12357, 'Docs',      'iPad Air',        'Safari',  'Denver, CO',        '4 days'),
    (100012, 12346, 'Pricing',   'Galaxy S24',      'Chrome',  'Miami, FL',         '1 day 8 hours'),
    (100013, 12346, 'Home page', 'Galaxy S24',      'Chrome',  'Miami, FL',         '1 day 9 hours'),
    (100014, 12348, 'Settings',  'ThinkPad X1',     'Firefox', 'New York, NY',      '2 days 2 hours'),
    (100015, 12348, 'Billing',   'ThinkPad X1',     'Firefox', 'New York, NY',      '2 days 1 hour'),
    (100016, 12347, 'Pricing',   'MacBook Air',     'Safari',  'Boston, MA',        '5 days'),
    (100017, 12347, 'Home page', 'MacBook Air',     'Safari',  'Boston, MA',        '12 days'),
    (100018, 12350, 'Home page', 'Chromebook',      'Chrome',  'Phoenix, AZ',       '7 hours'),
    (100019, 12350, 'Docs',      'Chromebook',      'Chrome',  'Phoenix, AZ',       '15 days'),
    (100020, 12352, 'Settings',  'HP Spectre',      'Edge',    'Atlanta, GA',       '9 days'),
    (100021, 12352, 'Dashboard', 'HP Spectre',      'Edge',    'Atlanta, GA',       '1 day 12 hours'),
    (100022, 12353, 'Pricing',   'MacBook Pro',     'Chrome',  'San Francisco, CA', '6 hours'),
    (100023, 12353, 'Billing',   'MacBook Pro',     'Chrome',  'San Francisco, CA', '30 days'),
    (100024, 12355, 'Home page', 'iPhone 14',       'Safari',  'Portland, OR',      '2 days 9 hours'),
    (100025, 12355, 'Pricing',   'iPhone 14',       'Safari',  'Portland, OR',      '25 days'),
    (100026, 12356, 'Settings',  'Dell Inspiron',   'Firefox', 'Dallas, TX',        '3 days 4 hours'),
    (100027, 12356, 'Docs',      'Dell Inspiron',   'Firefox', 'Dallas, TX',        '8 days'),
    (100028, 12358, 'Dashboard', 'Surface Pro',     'Edge',    'San Diego, CA',     '1 day 1 hour'),
    (100029, 12358, 'Pricing',   'Surface Pro',     'Edge',    'San Diego, CA',     '14 days'),
    (100030, 12359, 'Home page', 'Galaxy Tab S9',   'Chrome',  'Nashville, TN',     '5 days 3 hours'),
    (100031, 12359, 'Settings',  'Galaxy Tab S9',   'Chrome',  'Nashville, TN',     '18 days'),
    (100032, 12345, 'Pricing',   'MacBook Pro',     'Chrome',  'Los Angeles, CA',   '9 days'),
    (100033, 12348, 'Pricing',   'ThinkPad X1',     'Firefox', 'New York, NY',      '5 days')
) AS v(id, user_id, page, device, browser, location, ago);