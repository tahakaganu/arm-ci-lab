"""Unit tests for the demo app."""
from app import add


def test_add():
    """add() returns the arithmetic sum."""
    assert add(2, 3) == 5
