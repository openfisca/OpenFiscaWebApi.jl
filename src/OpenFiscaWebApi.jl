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



module OpenFiscaWebApi


export make_app, start


using Biryani
using Biryani.JsonConverters
using Dates
using HttpCommon: Headers, Response, STATUS_CODES
import JSON
using Meddle: handle, MeddleRequest, middleware, Midware, respond
import Morsel

using OpenFiscaCore: calculate, get_variable, Simulation, to_scenario, YearPeriod
using OpenFiscaFrance: EntityDefinition, tax_benefit_system


include("controllers/calculate.jl")
include("controllers/entities.jl")
include("responses.jl")


function make_app()
  app = Morsel.app()
  # with(app, cors) do app
  Morsel.post(app, "/api/<api_version::Int>/calculate") do req::MeddleRequest, res::Response
    if req.params[:api_version] === 2
      return handle_calculate_version_2(req, res)
    end
    return handle(middleware(NotFound, ApiData(), JsonData), req, res)
  end
  Morsel.get(app, "/api/<api_version::Int>/entities") do req::MeddleRequest, res::Response
    if req.params[:api_version] === 2
      return handle_entities_version_2(req, res)
    end
    return handle(middleware(NotFound, ApiData(), JsonData), req, res)
  end
  # end
  return app
end


function start(port::Integer)
  app = make_app()
  Morsel.start(app, port)
end


end # module
