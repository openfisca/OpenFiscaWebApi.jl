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


facts("calculate controller") do

  const test_case = JSON.parsefile(joinpath(Pkg.dir("OpenFiscaWebApi"), "test", "data", "calculate_simulation_1.json"))

  context("empty body") do
    res = handle_calculate_version_1(MeddleRequest(method = "POST"), Response())
    @fact res.status => 400
    @fact res.headers["Content-Type"] => "application/json; charset=utf-8"
    data = JSON.parse(res.data)
    value, error = Convertible(data) |> pipe(
      test_isa(Dict),
      struct(
        [
          "error" => require,
        ],
        default = noop,
      ),
    ) |> to_value_error
    @fact error => exactly(nothing)
  end

  context("wrong req Content-Type") do
    req = MeddleRequest(data = JSON.json(test_case), method = "POST")
    res = handle_calculate_version_1(req, Response())
    @fact res.status => 400
    @fact res.headers["Content-Type"] => "application/json; charset=utf-8"
    data = JSON.parse(res.data)
    value, error = Convertible(data) |> pipe(
      test_isa(Dict),
      struct(
        [
          "error" => pipe(
            struct(
              [
                "errors" => struct(
                  [
                    "content_type" => require,
                  ],
                  default = noop,
                )
              ],
              default = noop,
            ),
            require,
          ),
        ],
        default = noop,
      ),
    ) |> to_value_error
    @fact error => exactly(nothing)
  end

  context("invalid body") do
    res = handle_calculate_version_1(MeddleRequest(data = "XXX", headers = json_headers, method = "POST"), Response())
    @fact res.status => 400
    @fact res.headers["Content-Type"] => "application/json; charset=utf-8"
    data = JSON.parse(res.data)
    value, error = Convertible(data) |> pipe(
      test_isa(Dict),
      struct(
        [
          "error" => pipe(
            struct(
              [
                "errors" => struct(
                  [
                    "req_data" => require,
                  ],
                  default = noop,
                )
              ],
              default = noop,
            ),
            require,
          ),
        ],
        default = noop,
      ),
    ) |> to_value_error
    @fact error => exactly(nothing)
  end

  context("test case") do
    req = MeddleRequest(data = JSON.json(test_case), headers = json_headers, method = "POST")
    res = handle_calculate_version_1(req, Response())
    @fact res.status => 200
    @fact res.headers["Content-Type"] => "application/json; charset=utf-8"
    data = JSON.parse(res.data)
    value, error = Convertible(data) |> pipe(
      test_isa(Dict),
      struct(
        [
          "error" => test_nothing,
          "value" => pipe(
            test_isa(Array),
            uniform_sequence(
              pipe(
                test_isa(Dict),
                require,
              ),
            ),
            require,
          ),
        ],
        default = noop,
      ),
    ) |> to_value_error
    @fact error => exactly(nothing)
  end

  context("test case with trace") do
    test_case_with_trace = deepcopy(test_case)
    test_case_with_trace["trace"] = true
    req = MeddleRequest(data = JSON.json(test_case_with_trace), headers = json_headers, method = "POST")
    res = handle_calculate_version_1(req, Response())
    @fact res.status => 200
    @fact res.headers["Content-Type"] => "application/json; charset=utf-8"
    data = JSON.parse(res.data)
    value, error = Convertible(data) |> pipe(
      test_isa(Dict),
      struct(
        [
          "error" => test_nothing,
          "tracebacks" => pipe(
            test_isa(Array),
            uniform_sequence(
              pipe(
                test_isa(Dict),
                require,
              ),
            ),
            require,
          ),
          "value" => pipe(
            test_isa(Array),
            uniform_sequence(
              pipe(
                test_isa(Dict),
                require,
              ),
            ),
            require,
          ),
        ],
        default = noop,
      ),
    ) |> to_value_error
    @fact error => exactly(nothing)
  end

end
