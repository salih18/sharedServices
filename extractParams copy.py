import re
import json

def convert_value(type, value):
    if type == "bool":
        return value.lower() == "true"
    elif type == "int":
        return int(value)
    elif type == "array":
        # Remove '[' and ']' from the start and end of the string
        value = value.strip()[1:-1].strip()
        # Check if the value is empty after removing brackets
        if value == '':
            return []
        else:
            # Split the array values by whitespace and remove the single quotes around each value
            return [item.strip(' \'') for item in value.split()]
    elif type == "object":
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return value
    else:
        return value.strip('\'') if value != "''" else ""

# Read the Bicep file
with open('main.bicep', 'r') as file:
    data = file.read()

# Use regular expressions to find parameters
parameters = re.findall(r'param (\w+) (\w+)(?: = (.*))?', data)

# Create a dictionary to store the parameters
parameters_dict = {}

# Loop through the parameters and add them to the dictionary
for parameter in parameters:
    name, type, default_value = parameter
    if default_value:
        parameters_dict[name] = convert_value(type, default_value.strip())
    else:
        parameters_dict[name] = "<value>"

# Write the parameters to a JSON file
with open('parameters.json', 'w') as file:
    json.dump(parameters_dict, file, indent=4)