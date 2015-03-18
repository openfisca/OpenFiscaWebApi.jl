# OpenFisca -- A versatile microsimulation software
# By: OpenFisca Team <contact@openfisca.fr>
#
# Copyright (C) 2011, 2012, 2013, 2014, 2015 OpenFisca Team
# https://github.com/openfisca
#
# This file is part of OpenFisca.
#
# OpenFisca is free software; you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# OpenFisca is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


function fill_decomposition_json!(node::Dict, simulations::Array{Simulation})
  if haskey(node, "children")
    for child in node["children"]
      fill_decomposition_json!(child, simulations)
    end
    node["values"] = mapreduce(child -> child["values"], .+, node["children"])
  else
    simulations_values = mapreduce(vcat, simulations) do simulation
      variable_at_period = calculate(simulation, node["code"], accept_other_period = true)
      if variable_at_period.period != simulation.period
        variable_at_period = calculate_add_divide(simulation, node["code"])
      end
      array = get_array(variable_at_period)
      foyer_fiscal = simulation.entity_by_name["foyer_fiscal"]
      person = get_person(simulation)
      variable_entity = get_entity(get_variable(variable_at_period))
      if variable_entity === person
        array_handle = sum_person_in_entity(variable_at_period, foyer_fiscal)
        array = get_array(array_handle)
      elseif variable_entity !== foyer_fiscal
        array_handle = entity_to_person(variable_at_period, Role(1))
        array_handle = sum_person_in_entity(array_handle, foyer_fiscal, variable_at_period.period)
        array = get_array(array_handle)
      end
      return array
    end
    node["values"] = simulations_values
  end
end


function handle_simulate_version_1(req::MeddleRequest, res::Response)
  @assert req.http_req.method == "POST"
  req.params[:api_version] = 1

  input_to_params = pipe(
    # TODO Check Content-Type
    input_to_json,
    test_isa(Dict),
    require,
  )
  params, error = Convertible(req.http_req.data) |> input_to_params |> to_value_error
  if error !== nothing
    return handle(middleware(BadRequest, APIData(["req_data" => error]), JSONData), req, res)
  end

  default_scenario_json = [
    "period" => YearPeriod(DEFAULT_YEAR),
    "test_case" => [
      "individus" => [(String => Any)[]],
    ],
  ]
  params_to_data = struct(
    [
      "scenarios" => pipe(
        default([default_scenario_json]),
        uniform_sequence(
          require, # Real conversion is done after.
        ),
        test(scenarios -> length(scenarios) >= 1, error = N_("At least one scenario is required")),
        test(scenarios -> length(scenarios) <= 100, error = N_("There can't be more than 100 scenarios")),
        require,
      ),
      "validate" => pipe(
        test_isa(Union(Bool, Int)),
        to_bool,
        default(false),
      ),
    ],
  )
  data, errors = Convertible(params) |> params_to_data |> to_value_error
  if errors === nothing
    scenarios, errors = Convertible(data["scenarios"]) |> uniform_sequence(
      to_scenario(tax_benefit_system, repair = data["validate"]),
      require,
    ) |> to_value_error
  end
  if errors !== nothing
    return handle(middleware(BadRequest, APIData(["scenarios" => errors]), JSONData), req, res)
  end

  decomposition_json = to_json(default_decomposition)
  simulations::Array{Simulation} = map(scenario -> Simulation(scenario, debug = false, trace = false), scenarios)
  fill_decomposition_json!(decomposition_json, simulations)

  response_data = [
    "params" => params,
    "value" => decomposition_json,
  ]
  return handle(middleware(APIData(response_data), JSONData), req, res)
end


function to_json(decomposition_node::DecompositionNode; root = true)
  json_node = to_json(decomposition_node.name, decomposition_node.label, decomposition_node.short_label)
  json_node["children"] = map(child -> isa(child, DecompositionNode) ? to_json(child; root = false) : to_json(child),
    decomposition_node.children)
  if root
    json_node["@context"] = "http://openfisca.fr/contexts/decomposition.jsonld"
  end
  json_node
end

to_json(name::String, label::String, short_label::String) = (String => Any)[
  "@type" => "Node",
  "code" => name,
  "color" => [rand(0:255), rand(0:255), rand(0:255)], # Colors are not implemented in Julia, a random color is picked.
  "name" => label,
  "short_name" => short_label,
]

to_json(variable_definition::VariableDefinition) = to_json(variable_definition.name, variable_definition.label,
  variable_definition.label) # TODO Implement short label for VariableDefinition.
