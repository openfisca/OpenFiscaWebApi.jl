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


using Biryani
using Dates
import JSON

using OpenFiscaCore: calculate, Simulation, to_scenario, YearPeriod
using OpenFiscaFrance: tax_benefit_system


function handle_calculate(req, res)
  inputs = req.http_req.data
  params = JSON.parse(inputs) # TODO use biryani converter
  params_to_data = struct(
    [
      "variables" => pipe(
        test_isa(Array),
        uniform_sequence(
          test_isa(String),
          require,
        ),
        empty_to_nothing,
        require,
      ),
    ],
  )
  data, errors = Convertible(params) |> params_to_data |> to_value_error
  if errors !== nothing
    return bad_request(res, errors = errors)
  end

  scenario = Convertible([
    "test_case" => [
      "individus" => [(String => Any)[]],
    ],
    "year" => 2013,
  ]) |> to_scenario(tax_benefit_system, repair = true) |> to_value
  simulation = Simulation(scenario, debug = true)
  value = calculate(simulation, "irpp")
  response_data = [
    "value" => value,
  ]
  return respond_json(res, data = response_data)
end
