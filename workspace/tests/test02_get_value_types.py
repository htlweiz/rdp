"""Test the get value types method from crud."""


import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from rdp.crud.crud import Crud, Base, Value, ValueType

#Create an in-memory database and set up the SQLAlchemy engine
engine = create_engine("sqlite:///:memory:")
Base.metadata.create_all(engine)

@pytest.fixture
def crud_instance():
    """Fixture that creates and returns a Crud instance for testing."""
    return Crud(engine)


def test_get_value_types_empty_database(crud_instance):
    """Test if get_value_types returns an empty list when no value types are in the database."""

    #Call get_value_types on an empty database
    value_types = crud_instance.get_value_types()
    
    #Assert that the returned list is empty
    assert len(value_types) == 0


def test_get_value_types(crud_instance):
    """Test if the right value types are returned."""

    #Add two value types to the database
    crud_instance.add_or_update_value_type(value_type_name="TestType1", value_type_unit="TestUnit1")
    crud_instance.add_or_update_value_type(value_type_name="TestType2", value_type_unit="TestUnit2")
    
    #Call get_value_types to retrieve all value types
    value_types = crud_instance.get_value_types()
    
    #Assert that there are exactly two value types in the database
    assert len(value_types) == 2
    
    #Assert that the names of the returned value types match the added ones
    assert value_types[0].type_name == "TestType1"
    assert value_types[1].type_name == "TestType2"


