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


function handle_entities_version_2(req::MeddleRequest, res::Response)
  @assert req.http_req.method == "GET"

  entities = [
    name => [
      "is_person" => definition.is_person,
      "name" => definition.name,
      "name_plural" => definition.name_plural,
    ]
    for (name, definition) in tax_benefit_system.entity_definition_by_name
  ]
  const RESPONSE_DATA = [
    "entities" => entities,
  ]
  return res, middleware(APIData(RESPONSE_DATA), JSONData)
end
