from unittest.mock import MagicMock, patch

import pytest
import requests

from ingestion.fetch_rates import fetch_rates, transform

SAMPLE_PAYLOAD = {
    "amount": 1.0,
    "base": "USD",
    "start_date": "2020-11-02",
    "end_date": "2020-11-03",
    "rates": {
        "2020-11-02": {"EUR": 0.8584, "GBP": 0.7741},
        "2020-11-03": {"EUR": 0.8537, "GBP": 0.7650},
    },
}


def test_transform_returns_one_row_per_date_and_currency():
    df = transform(SAMPLE_PAYLOAD)

    assert len(df) == 4
    assert list(df.columns) == ["rate_date", "base_currency", "currency", "rate", "loaded_at"]
    assert set(df["currency"]) == {"EUR", "GBP"}
    assert (df["base_currency"] == "USD").all()
    assert (df["rate"] > 0).all()


def test_transform_raises_when_no_rates():
    with pytest.raises(ValueError):
        transform({"base": "USD", "rates": {}})


@patch("ingestion.fetch_rates.time.sleep")
@patch("ingestion.fetch_rates.requests.get")
def test_fetch_rates_retries_then_succeeds(mock_get, mock_sleep):
    ok_response = MagicMock()
    ok_response.json.return_value = SAMPLE_PAYLOAD
    mock_get.side_effect = [requests.ConnectionError("network down"), ok_response]

    result = fetch_rates("2020-11-02", "2020-11-03")

    assert result == SAMPLE_PAYLOAD
    assert mock_get.call_count == 2
    mock_sleep.assert_called_once()


@patch("ingestion.fetch_rates.time.sleep")
@patch("ingestion.fetch_rates.requests.get", side_effect=requests.Timeout("too slow"))
def test_fetch_rates_raises_after_max_retries(mock_get, mock_sleep):
    with pytest.raises(requests.Timeout):
        fetch_rates("2020-11-02", "2020-11-03", retries=3)

    assert mock_get.call_count == 3
