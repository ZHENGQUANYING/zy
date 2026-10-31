-- =============================================================
-- Todo List 数据库设计（SQLite）
-- 单机本地应用，单用户场景，支持分类、标签、子任务、提醒
-- =============================================================

PRAGMA foreign_keys = ON;

-- -------------------------------------------------------------
-- 1. 分类表：工作 / 生活 / 学习 等清单分组
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT    NOT NULL UNIQUE,          -- 分类名
    color       TEXT    NOT NULL DEFAULT '#409eff', -- 展示颜色（hex）
    icon        TEXT,                             -- 图标名（前端映射，可空）
    sort_order  INTEGER NOT NULL DEFAULT 0,       -- 手动排序
    created_at  TEXT    NOT NULL DEFAULT (datetime('now', 'localtime')),
    updated_at  TEXT    NOT NULL DEFAULT (datetime('now', 'localtime'))
);

-- -------------------------------------------------------------
-- 2. 任务主表
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS todos (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    title        TEXT    NOT NULL CHECK (length(trim(title)) > 0),
    notes        TEXT,                            -- 备注 / 详细描述（Markdown）
    category_id  INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    parent_id    INTEGER REFERENCES todos(id)     -- 子任务：指向父任务
                          ON DELETE CASCADE,
    status       TEXT    NOT NULL DEFAULT 'pending'
                          CHECK (status IN ('pending', 'in_progress', 'done')),
    priority     INTEGER NOT NULL DEFAULT 0
                          CHECK (priority IN (0, 1, 2, 3)),  -- 0无 1低 2中 3高
    due_date     TEXT,                            -- 截止日期 YYYY-MM-DD
    remind_at    TEXT,                            -- 提醒时间 YYYY-MM-DD HH:MM
    is_pinned    INTEGER NOT NULL DEFAULT 0,      -- 置顶 0/1
    sort_order   INTEGER NOT NULL DEFAULT 0,      -- 拖拽排序
    completed_at TEXT,                            -- 完成时间（status=done 时写入）
    created_at   TEXT    NOT NULL DEFAULT (datetime('now', 'localtime')),
    updated_at   TEXT    NOT NULL DEFAULT (datetime('now', 'localtime')),
    -- SQLite 不允许外键做 CHECK 跨表校验，层级深度由应用层限制为 2 层
    CHECK (id != parent_id)
);

-- 常用查询索引
CREATE INDEX IF NOT EXISTS idx_todos_status      ON todos(status);
CREATE INDEX IF NOT EXISTS idx_todos_due_date    ON todos(due_date);
CREATE INDEX IF NOT EXISTS idx_todos_category    ON todos(category_id);
CREATE INDEX IF NOT EXISTS idx_todos_parent      ON todos(parent_id);

-- -------------------------------------------------------------
-- 3. 标签表 + 任务-标签关联表（多对多）
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tags (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    name       TEXT NOT NULL UNIQUE,
    color      TEXT NOT NULL DEFAULT '#909399',
    created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
);

CREATE TABLE IF NOT EXISTS todo_tags (
    todo_id INTEGER NOT NULL REFERENCES todos(id) ON DELETE CASCADE,
    tag_id  INTEGER NOT NULL REFERENCES tags(id)  ON DELETE CASCADE,
    PRIMARY KEY (todo_id, tag_id)
);

CREATE INDEX IF NOT EXISTS idx_todo_tags_tag ON todo_tags(tag_id);

-- -------------------------------------------------------------
-- 4. 设置表：键值存储前端偏好（主题、默认视图等）
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS settings (
    key        TEXT PRIMARY KEY,
    value      TEXT NOT NULL,                     -- JSON 字符串
    updated_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
);

-- -------------------------------------------------------------
-- 5. updated_at 自动更新触发器
-- -------------------------------------------------------------
CREATE TRIGGER IF NOT EXISTS trg_todos_updated
AFTER UPDATE ON todos
FOR EACH ROW
BEGIN
    UPDATE todos SET updated_at = datetime('now', 'localtime') WHERE id = OLD.id;
END;

CREATE TRIGGER IF NOT EXISTS trg_categories_updated
AFTER UPDATE ON categories
FOR EACH ROW
BEGIN
    UPDATE categories SET updated_at = datetime('now', 'localtime') WHERE id = OLD.id;
END;

-- -------------------------------------------------------------
-- 6. 内置初始数据
-- -------------------------------------------------------------
INSERT OR IGNORE INTO categories (id, name, color, icon, sort_order) VALUES
    (1, '收件箱', '#409eff', 'inbox',     0),
    (2, '工作',   '#e6a23c', 'briefcase', 1),
    (3, '生活',   '#67c23a', 'home',      2),
    (4, '学习',   '#b88230', 'book',      3);
