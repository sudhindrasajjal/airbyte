#
# MIT License
#
# Copyright (c) 2020 Airbyte
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#


import logging

import requests
from airbyte_cdk.sources.streams.http.auth import NoAuth, Oauth2Authenticator, TokenAuthenticator
from requests import Response

LOGGER = logging.getLogger(__name__)


def test_token_authenticator():
    """
    Should match passed in token, no matter how many times token is retrieved.
    """
    token = TokenAuthenticator("test-token")
    header = token.get_auth_header()
    assert {"Authorization": "Bearer test-token"} == header
    header = token.get_auth_header()
    assert {"Authorization": "Bearer test-token"} == header


def test_no_auth():
    """
    Should always return empty body, no matter how many times token is retrieved.
    """
    no_auth = NoAuth()
    assert {} == no_auth.get_auth_header()
    no_auth = NoAuth()
    assert {} == no_auth.get_auth_header()


class TestOauth2Authenticator:
    """
    Test class for OAuth2Authenticator.
    """

    refresh_endpoint = "refresh_end"
    client_id = "client_id"
    client_secret = "client_secret"
    refresh_token = "refresh_token"

    def test_get_auth_header_fresh(self, mocker):
        """
        Should not retrieve new token if current token is valid.
        """
        oauth = Oauth2Authenticator(
            TestOauth2Authenticator.refresh_endpoint,
            TestOauth2Authenticator.client_id,
            TestOauth2Authenticator.client_secret,
            TestOauth2Authenticator.refresh_token,
        )

        mocker.patch.object(Oauth2Authenticator, "refresh_access_token", return_value=("access_token", 1000))
        header = oauth.get_auth_header()
        assert {"Authorization": "Bearer access_token"} == header

    def test_get_auth_header_expired(self, mocker):
        """
        Should retrieve new token if current token is expired.
        """
        oauth = Oauth2Authenticator(
            TestOauth2Authenticator.refresh_endpoint,
            TestOauth2Authenticator.client_id,
            TestOauth2Authenticator.client_secret,
            TestOauth2Authenticator.refresh_token,
        )

        expire_immediately = 0
        mocker.patch.object(Oauth2Authenticator, "refresh_access_token", return_value=("access_token_1", expire_immediately))
        oauth.get_auth_header()  # Set the first expired token.

        valid_100_secs = 100
        mocker.patch.object(Oauth2Authenticator, "refresh_access_token", return_value=("access_token_2", valid_100_secs))
        header = oauth.get_auth_header()
        assert {"Authorization": "Bearer access_token_2"} == header

    def test_refresh_request_body(self):
        """
        Request body should match given configuration.
        """
        scopes = ["scope1", "scope2"]
        oauth = Oauth2Authenticator(
            TestOauth2Authenticator.refresh_endpoint,
            TestOauth2Authenticator.client_id,
            TestOauth2Authenticator.client_secret,
            TestOauth2Authenticator.refresh_token,
            scopes,
        )
        body = oauth.get_refresh_request_body()
        expected = {
            "grant_type": "refresh_token",
            "client_id": "client_id",
            "client_secret": "client_secret",
            "refresh_token": "refresh_token",
            "scopes": scopes,
        }
        assert body == expected

    def test_refresh_access_token(self, mocker):
        oauth = Oauth2Authenticator(
            TestOauth2Authenticator.refresh_endpoint,
            TestOauth2Authenticator.client_id,
            TestOauth2Authenticator.client_secret,
            TestOauth2Authenticator.refresh_token,
        )
        resp = Response()
        resp.status_code = 200

        mocker.patch.object(requests, "request", return_value=resp)
        mocker.patch.object(resp, "json", return_value={"access_token": "access_token", "expires_in": 1000})
        token = oauth.refresh_access_token()

        assert ("access_token", 1000) == token
