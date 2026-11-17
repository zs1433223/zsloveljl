-- 恋爱记录网站数据库初始化脚本
-- 数据库：PostgreSQL 14+
-- 执行方式：psql -U postgres -d love_database -f init_db.sql

-- 创建数据库（如果需要）
-- CREATE DATABASE love_database;
-- \c love_database

-- 扩展模块
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. 用户表
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    hashed_password VARCHAR(128) NOT NULL,
    nickname VARCHAR(50) DEFAULT '',
    avatar VARCHAR(500) DEFAULT '',
    wechat_id VARCHAR(100) DEFAULT '',
    email VARCHAR(100) DEFAULT '',
    role VARCHAR(20) DEFAULT 'user',  -- user, admin
    bio VARCHAR(500) DEFAULT '',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. 关系表（情侣信息）
CREATE TABLE IF NOT EXISTS relationships (
    id SERIAL PRIMARY KEY,
    partner1_name VARCHAR(50) NOT NULL,
    partner1_avatar VARCHAR(500) DEFAULT '',
    partner2_name VARCHAR(50) NOT NULL,
    partner2_avatar VARCHAR(500) DEFAULT '',
    start_date DATE NOT NULL,
    partner1_birthday DATE,
    partner2_birthday DATE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. 恋爱记录表
CREATE TABLE IF NOT EXISTS loverecords (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT DEFAULT '',
    record_date DATE NOT NULL,
    is_private BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'published',  -- published, draft
    views INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 4. 记录媒体表（图片、视频）
CREATE TABLE IF NOT EXISTS record_media (
    id SERIAL PRIMARY KEY,
    record_id INTEGER REFERENCES loverecords(id) ON DELETE CASCADE,
    media_type VARCHAR(20) NOT NULL,  -- image, video
    media_url VARCHAR(500) NOT NULL,
    caption VARCHAR(200) DEFAULT '',
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 5. 评论表
CREATE TABLE IF NOT EXISTS comments (
    id SERIAL PRIMARY KEY,
    record_id INTEGER REFERENCES loverecords(id) ON DELETE CASCADE,
    parent_id INTEGER REFERENCES comments(id) ON DELETE CASCADE,
    nickname VARCHAR(50) NOT NULL,
    avatar VARCHAR(500) DEFAULT '',
    content TEXT NOT NULL,
    ip VARCHAR(45) DEFAULT '',
    status VARCHAR(20) DEFAULT 'pending',  -- pending, approved, rejected
    likes INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 6. 里程碑表（完成事项树）
CREATE TABLE IF NOT EXISTS milestones (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT DEFAULT '',
    milestone_type VARCHAR(50) DEFAULT 'achievement',  -- achievement, location, special
    achieved_date DATE,
    is_completed BOOLEAN DEFAULT FALSE,
    parent_id INTEGER REFERENCES milestones(id) ON DELETE CASCADE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 7. 地图点位表
CREATE TABLE IF NOT EXISTS map_points (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT DEFAULT '',
    longitude DOUBLE PRECISION NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    city VARCHAR(50) DEFAULT '',
    province VARCHAR(50) DEFAULT '',
    country VARCHAR(50) DEFAULT 'China',
    point_type VARCHAR(50) DEFAULT 'location',  -- location, achievement, special
    cover_image VARCHAR(500) DEFAULT '',
    photos TEXT DEFAULT '[]',  -- JSON array of image URLs
    videos TEXT DEFAULT '[]',  -- JSON array of video URLs
    sort_order INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'published',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 8. 站点配置表
CREATE TABLE IF NOT EXISTS site_config (
    id SERIAL PRIMARY KEY,
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT DEFAULT '',
    description VARCHAR(200) DEFAULT '',
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 插入默认配置
INSERT INTO site_config (key, value, description) VALUES
('site_title', '我们的恋爱记录', '站点标题'),
('site_description', '记录我们的甜蜜时光', '站点描述'),
('partner1_name', '他/她', '伴侣1昵称'),
('partner2_name', '我', '伴侣2昵称'),
('start_date', '2024-01-01', '在一起日期'),
('partner1_birthday', '', '伴侣1生日'),
('partner2_birthday', '', '伴侣2生日');

-- 插入默认管理员账号（密码: admin123）
-- 注意：实际部署时应使用 bcrypt 加密后的密码
INSERT INTO users (username, hashed_password, nickname, role) VALUES
('admin', '$2b$12$LQv3c1yqBWVHx00z88K4T.Q7gXJ7l1g8K5t6vP9x2Y1z8K4T.Q7gX', '管理员', 'admin');

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_loverecords_status ON loverecords(status);
CREATE INDEX IF NOT EXISTS idx_loverecords_record_date ON loverecords(record_date);
CREATE INDEX IF NOT EXISTS idx_comments_record_id ON comments(record_id);
CREATE INDEX IF NOT EXISTS idx_map_points_city ON map_points(city);
CREATE INDEX IF NOT EXISTS idx_milestones_type ON milestones(milestone_type);

-- 创建更新时间函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 创建触发器
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_relationships_updated_at BEFORE UPDATE ON relationships FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_loverecords_updated_at BEFORE UPDATE ON loverecords FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_milestones_updated_at BEFORE UPDATE ON milestones FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_map_points_updated_at BEFORE UPDATE ON map_points FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 添加 ALTER 语句支持（用于后续字段扩展）
-- ALTER TABLE users ADD COLUMN IF NOT EXISTS wechat_id VARCHAR(100) DEFAULT '';
-- ALTER TABLE relationships ADD COLUMN IF NOT EXISTS partner1_birthday DATE;
-- ALTER TABLE relationships ADD COLUMN IF NOT EXISTS partner2_birthday DATE;
