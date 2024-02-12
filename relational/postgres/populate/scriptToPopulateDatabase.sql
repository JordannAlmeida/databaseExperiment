--- Create tables
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    birthdate DATE
);
CREATE TABLE posts(
  id      SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id),
  title   VARCHAR(100) NOT NULL UNIQUE
);
CREATE TABLE comments(
  id      SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id),
  post_id INTEGER NOT NULL REFERENCES posts(id),
  body    VARCHAR(500) NOT NULL,
  likes BIGINT
);

-- Insert fake data users
do $$
DECLARE
    suffixes VARCHAR[] := ARRAY['gmail.com', 'outlook.com', 'hotmail.com'];
    i INT;
BEGIN
    FOR i IN 1..10000 LOOP
        INSERT INTO users (name, email, birthdate)
        VALUES (
            'user_' || i,                                      -- name prefix
            'user_' || i || '@' || suffixes[1 + (i % 3)],  -- email
            (select timestamp '1970-01-01 00:00:00' +
       					random() * (timestamp '2006-01-10 00:00:00' -
                   		timestamp '1970-01-01 00:00:00'))   -- random birthdate between 1970-01-01 and 2004-01-01
        );
    END LOOP;
end $$;


--- generate random posts
INSERT INTO posts(user_id, title)
WITH expanded AS (
  SELECT RANDOM(), seq, u.id AS user_id
  FROM GENERATE_SERIES(1, 50000) seq, users u
), shuffled AS (
  SELECT e.*
  FROM expanded e
  INNER JOIN (
    SELECT ei.seq, MIN(ei.random) FROM expanded ei GROUP BY ei.seq
  ) em ON (e.seq = em.seq AND e.random = em.min)
  ORDER BY e.seq
)
SELECT
  s.user_id,
  'It is ' || s.seq || ' ' || (
    CASE (RANDOM() * 5)::INT
      WHEN 0 THEN 'sql'
      WHEN 1 THEN 'elixir'
      WHEN 2 THEN 'ruby'
      WHEN 3 THEN 'java'
      WHEN 4 THEN 'C#'
      WHEN 5 THEN 'python'
    END
  ) as title
FROM shuffled s;

--- generate random comments
do $$
declare
  maxUsers int;
  maxPosts int;
  i INT;
begin
	select count(*) into maxUsers from users;
    select count(*) into maxPosts from posts;
    FOR i IN 1..1000 LOOP
        INSERT INTO comments (user_id, post_id, body, likes)
        VALUES (
            (select cast(random() * (maxUsers - 2) as INT)),
            (select cast(random() * (maxPosts - 2) as INT)),
            'Here some comment ' || i,
            (select cast(random() * 200 as INT))
        );
    END LOOP;
end $$;