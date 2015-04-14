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


facts("field controller") do

  const validate_res_data = pipe(
    test_isa(Dict),
    struct(
      [
        "error" => test_nothing,
        "value" => pipe(
          struct(
            [
              "formula" => struct(
                [
                  "line_number" => test_isa(Integer),
                  "module" => test_isa(String),
                  "source" => test_isa(String),
                ],
              ),
              "name" => pipe(test_isa(String), require),
            ],
            default = noop,
          ),
          require,
        ),
      ],
      default = noop,
    ),
  )

  context("no params returns revdisp data") do
    res = handle_field_version_1(MeddleRequest(method = "GET"), Response())
    @fact res.status => 200
    @fact res.headers["Content-Type"] => "application/json; charset=utf-8"
    data = JSON.parse(res.data)
    value, error = Convertible(data) |> validate_res_data |> to_value_error
    @fact error => exactly(nothing)
    @fact data["value"]["name"] => "revdisp"
  end

end
