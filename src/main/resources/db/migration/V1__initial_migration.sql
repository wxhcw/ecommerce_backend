CREATE TABLE addresses
(
    id      BIGSERIAL NOT NULL,
    street  VARCHAR(255) NOT NULL,
    city    VARCHAR(255) NOT NULL,
    state   VARCHAR(255) NOT NULL,
    zip     VARCHAR(255) NOT NULL,
    user_id BIGINT       NOT NULL,
    CONSTRAINT addresses_pkey PRIMARY KEY (id)
);

CREATE TABLE categories
(
    id   SMALLSERIAL NOT NULL,
    name VARCHAR(255) NOT NULL,
    CONSTRAINT categories_pkey PRIMARY KEY (id)
);

CREATE TABLE products
(
    id          BIGSERIAL NOT NULL,
    name        VARCHAR(255)   NOT NULL UNIQUE,
    price       DECIMAL(10, 2) NOT NULL,
    description TEXT           NOT NULL,
    category_id SMALLINT NULL,
    CONSTRAINT products_pkey PRIMARY KEY (id),
    image_url VARCHAR(500) NOT NULL DEFAULT 'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8N3x8cHJvZHVjdHxlbnwwfHwwfHx8MA%3D%3D'
);

CREATE TABLE users
(
    id       BIGSERIAL NOT NULL,
    name     VARCHAR(255) NOT NULL,
    email    VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    CONSTRAINT users_pkey PRIMARY KEY (id)
);

CREATE TABLE profiles
(
    id             BIGINT NOT NULL,
    bio            TEXT NULL,
    phone_number   VARCHAR(15) NULL,
    date_of_birth  DATE NULL,
    loyalty_points INTEGER DEFAULT 0 NULL,
    CONSTRAINT profiles_pkey PRIMARY KEY (id)
);

CREATE TABLE wishlist
(
    product_id BIGINT NOT NULL,
    user_id    BIGINT NOT NULL,
    CONSTRAINT wishlist_pkey PRIMARY KEY (product_id, user_id)
);

-- 外键约束
ALTER TABLE addresses
    ADD CONSTRAINT addresses_users_id_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE NO ACTION;

CREATE INDEX addresses_users_id_fk ON addresses (user_id);

ALTER TABLE products
    ADD CONSTRAINT fk_category FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE NO ACTION;

CREATE INDEX fk_category ON products (category_id);

ALTER TABLE wishlist
    ADD CONSTRAINT fk_wishlist_on_product FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE;

ALTER TABLE wishlist
    ADD CONSTRAINT fk_wishlist_on_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE NO ACTION;

CREATE INDEX fk_wishlist_on_user ON wishlist (user_id);

ALTER TABLE profiles
    ADD CONSTRAINT profiles_ibfk_1 FOREIGN KEY (id) REFERENCES users (id) ON DELETE NO ACTION;