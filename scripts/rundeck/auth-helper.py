##
# Auth helper script for rundeck
#
# Example usage:
#   $ RUNDECK_SERVER_HOST=localhost RUNDECK_USER=admin RUNDECK_PASSWORD=admin python rundeck/auth-helper.py
##

## BEGIN: imports and logging
import os
import json
import requests
import logging

LOGGER = logging

# BEGIN: RUNDECK_* for auth and server-selection
RUNDECK_USER = os.environ.get('RUNDECK_USER', 'admin')
RUNDECK_PASSWORD = os.environ.get('RUNDECK_PASSWORD', 'admin')
RUNDECK_SERVER_SCHEMA = os.environ.get('RUNDECK_SERVER_SCHEMA', 'http')
RUNDECK_SERVER_HOST = os.environ.get('RUNDECK_SERVER_HOST', 'localhost')
RUNDECK_SERVER_PORT = os.environ.get('RUNDECK_SERVER_PORT', '4440')
RUNDECK_SERVER_URL_DEFAULT = '{}://{}:{}'.format(
    RUNDECK_SERVER_SCHEMA,
    RUNDECK_SERVER_HOST,
    RUNDECK_SERVER_PORT)
RUNDECK_SERVER_URL = os.environ.get(
    'RUNDECK_SERVER_URL', RUNDECK_SERVER_URL_DEFAULT)
RUNDECK_SERVER_URL_T = RUNDECK_SERVER_URL + "/{}"
RUNDECK_DEFAULT_HEADERS = dict(Accept='application/json')
# BEGIN: RUNDECK_API_* for some of the versioned API endpoints

RUNDECK_API_TOKEN = RUNDECK_SERVER_URL_T.format('api/19/token/{}')
RUNDECK_API_TOKENS = RUNDECK_SERVER_URL_T.format('api/37/tokens')
RUNDECK_API_LOGIN = RUNDECK_SERVER_URL_T.format('j_security_check')


def get_session(user, password):
    """
    get a session that persists the auth cookies,
    we'll use that for everything else
    """
    s = requests.Session()
    resp = s.post(
        RUNDECK_API_LOGIN,
        dict(j_username=user, j_password=password))
    if resp.url.endswith('user/login'):
        LOGGER.debug("auth ok")
    return s


def list_tokens(user=None, session=None):
    """
    returns {token_name_or_id: token_metadata}
    """
    assert all([user, session])
    resp = session.get(
        RUNDECK_API_TOKENS,
        params=dict(user=user,),
        headers=RUNDECK_DEFAULT_HEADERS)
    tokens = resp.json()
    tokens = dict([[t.get('name', t['id']), t] for t in tokens])
    return tokens


def rm_token(session=None, id=None):
    """
    removes a token.  requires id (not name)
    """
    resp = session.delete(RUNDECK_API_TOKEN.format(id))
    return resp


def create_token(user=None, name=None, session=None):
    """ """
    assert all([user, name, session])
    tmp_headers = RUNDECK_DEFAULT_HEADERS.copy()
    tmp_headers.update({"Content-Type": "application/json"})
    resp = session.post(
        RUNDECK_API_TOKENS,
        json.dumps(dict(
            name=name,
            user=user,
            roles='*',
            duration="30d",)),
        headers=tmp_headers)
    return resp.json()


def get_or_create_token(name=None, user=None, session=None, force=False):
    """ """
    tokens = list_tokens(user=user, session=session)
    if name in tokens:
        token = tokens[name]
        if force:
            msg = "forcing create, found and to be removed:\n{}"
            LOGGER.debug(msg.format(token))
            resp = rm_token(id=token['id'], session=session)
            LOGGER.debug(resp)
            return get_or_create_token(name=name, user=user, session=session)
        else:
            LOGGER.debug("skipping create, found:\n{}".format(token))
            return token
    else:
        LOGGER.debug("token missing, creating it")
        new_token = create_token(user=user, name=name, session=session)
        return new_token


def main(token_name):
    session = get_session(RUNDECK_USER, RUNDECK_PASSWORD)
    token = get_or_create_token(
        name=token_name, user=RUNDECK_USER,
        force=True, session=session,)
    LOGGER.debug(token)
    env = dict(
        TF_VAR_RUNDECK_USER=RUNDECK_USER,
        RUNDECK_USER=RUNDECK_USER,
        RUNDECK_TOKEN=token['token'],
        RUNDECK_SERVER_URL=RUNDECK_SERVER_URL,
        TF_VAR_RUNDECK_SERVER_URL=RUNDECK_SERVER_URL,
        TF_VAR_RUNDECK_TOKEN=token['token'],
    )
    print("; ".join(["export {}={}".format(k, v) for k, v in env.items()]))


if __name__ == '__main__':
    main(token_name="ansible-token")
