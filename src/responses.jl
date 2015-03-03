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


import Meddle: handle

handle(midware::Midware, req::MeddleRequest, res::Response) = handle([midware], req, res)


# Level 1 midwares

function ApiData(data::Dict)
  Midware() do req::MeddleRequest, res::Response
    function build_error_field()
      error_field = {
        "code" => res.status,
        "message" => STATUS_CODES[res.status],
      }
      if length(data) > 0
        error_field["errors"] = data
      end
      return error_field
    end
    const API_DATA = [
      "api_version" => req.params[:api_version],
      "method" => req.http_req.method,
    ]
    req.state[:response_data] = merge(
      Dict(),
      400 <= res.status <= 599 ? ["error" => build_error_field()] : data,
      API_DATA,
    )
    req, res
  end
end

ApiData() = ApiData(Dict())


JsonData = Midware() do req::MeddleRequest, res::Response
  res.headers["Content-Type"] = "application/json; charset=utf-8"
  res.data = JSON.json(req.state[:response_data])
  respond(req, res)
end


function Status(status::Int)
  Midware() do req::MeddleRequest, res::Response
    res.status = status
    req, res
  end
end


# Level 2 midwares

BadRequest = Status(400)


# Meddle.NotFound does not fit because it calls respond() which does not allow chaining with JSON midwares.
NotFound = Status(404)
