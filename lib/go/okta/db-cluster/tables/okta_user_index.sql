CREATE INDEX okta_user_index
ON cs.okta_user (
    login,
    created,
    last_updated
);
