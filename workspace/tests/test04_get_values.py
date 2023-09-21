"""Test the get values method from crud."""


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


def test_get_values_empty_database(crud_instance):
    """Test if get_values returns an empty list when no value types are in the database."""
    value_types = crud_instance.get_values()
    assert len(value_types) == 0


def test_get_values(crud_instance):
    """"Test if the right values returned."""

    #Add a value type to be used for the values.
    crud_instance.add_or_update_value_type(value_type_name="TestType", value_type_unit="TestUnit")
    
    #Retrieve the added value type.
    value_type = crud_instance.get_value_types()[0]

    #Add values using the added value type.
    crud_instance.add_value(value_time=12345, value_type=value_type.id, value_value=28.0)
    crud_instance.add_value(value_time=67890, value_type=value_type.id, value_value=19.9)
    
    #Retrieve values.
    values = crud_instance.get_values()

    assert len(values) == 2
    assert values[0].time == 12345 #Check if right value returned
    assert values[0].value == 28.0
    assert values[1].time == 67890
    assert values[1].value == 19.9


def test_get_values_no_filters(crud_instance):
    """Test if values returned when no filters are provided"""

    values = crud_instance.get_values()
    assert isinstance(values, list)


def test_get_values_with_value_type_filter(crud_instance):
    """Test if values returned when only value_type_id filter is provided"""

    value_type_id = 1  #Replace with a valid value_type_id
    values = crud_instance.get_values(value_type_id=value_type_id)
    assert isinstance(values, list)


def test_get_values_with_start_filter(crud_instance):
    """Test if values returned when only start filter is provided"""

    start = 100  #Replace with a valid start value
    values = crud_instance.get_values(start=start)
    assert isinstance(values, list)


def test_get_values_with_end_filter(crud_instance):
    """Test if values returned when when only end filter is provided"""

    end = 200  #Replace with a valid end value
    values = crud_instance.get_values(end=end)
    assert isinstance(values, list)


def test_get_values_with_all_filters(crud_instance):
    """Test if values returned when all filters are provided"""

    value_type_id = 1 #Replace with a valid value_type_id
    start = 100 #Replace with a valid start value
    end = 200 #Replace with a valid end value
    values = crud_instance.get_values(value_type_id=value_type_id, start=start, end=end)
    assert isinstance(values, list)

