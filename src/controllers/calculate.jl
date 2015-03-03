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


function build_test_case(scenario, simulation, variables)
    new_test_case = deepcopy(scenario.test_case)
    for variable_name in variables
        variable = get_variable(simulation, variable_name)
        variable_value_json = [
          string(period) => [
            variable.definition.cell_to_value_at_period_json(cell)
            for cell in array
          ]
          for (period, array) in variable.array_by_period
        ]
        entity_members = new_test_case[variable.definition.entity_definition.name_plural]
        for (entity_member_index, entity_member) in enumerate(entity_members)
            entity_member[variable.definition.name] = [
                period => array_json[entity_member_index]
                for (period, array_json) in variable_value_json
            ]
        end
    end
    return new_test_case
end


function handle_calculate_version_2(req::MeddleRequest, res::Response)
  input_to_params = pipe(
    input_to_json,
    test_isa(Dict),
    require,
  )
  params, error = Convertible(req.http_req.data) |> input_to_params |> to_value_error
  if error !== nothing
    return handle(middleware(BadRequest, ApiData([error]), JsonData), req, res)
  end

  const DEFAULT_SCENARIO = [
    "period" => YearPeriod(2013),
    "test_case" => [
      "individus" => [(String => Any)[]],
    ],
  ]
  const PARAMS_TO_DATA = struct(
    [
      "scenarios" => pipe(
        default([DEFAULT_SCENARIO]),
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
      "variables" => pipe(
        test_isa(Array),
        uniform_sequence(
          test_isa(String),
          test_in(tax_benefit_system.variable_definition_by_name),
          require,
        ),
        empty_to_nothing,
        require,
      ),
    ],
  )
  data, errors = Convertible(params) |> PARAMS_TO_DATA |> to_value_error
  if errors === nothing
    scenarios, errors = Convertible(data["scenarios"]) |> uniform_sequence(
      to_scenario(tax_benefit_system, repair = data["validate"]),
      require,
    ) |> to_value_error
  end
  if errors !== nothing
    return handle(middleware(BadRequest, ApiData(errors), JsonData), req, res)
  end

  simulations = map(scenarios) do scenario
    simulation = Simulation(scenario, debug = true, trace = false)
    for variable in data["variables"]
      calculate(simulation, variable)
    end
    return simulation
  end

  value = [
    build_test_case(scenario, simulation, data["variables"])
    for (scenario, simulation) in zip(scenarios, simulations)
  ]

  const RESPONSE_DATA = [
    "params" => params,
    "value" => value,
  ]
  return handle(middleware(ApiData(RESPONSE_DATA), JsonData), req, res)
end
