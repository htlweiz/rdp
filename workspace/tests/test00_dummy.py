""""Dummy Test Case."""


import pytest

def dummy_add(a, b):
    """"Addition of two numbers."""
    return a + b


def dummy_sub(a, b):
    """Subtraction of two numbers."""
    return a - b


def dummy_mult(a, b):
    """Multiplication of two numbers."""
    return a * b


def dummy_div(a, b):
    """Division of two numbers."""
    return a / b


def test_dummy():
    """This test should always pass."""
    assert dummy_add(2,3) == 5
    assert dummy_sub(10,2) == 8
    assert dummy_mult(2,10) == 20
    assert dummy_div(10,2) == 5 

