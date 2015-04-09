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


function handle_field_version_1(req::MeddleRequest, res::Response)
  @assert req.http_req.method == "GET"

  params_to_data = struct(
    [
      :variable => pipe(
        empty_to_nothing,
        test_in(tax_benefit_system.variable_definition_by_name),
        default("revdisp"),
      ),
    ],
  )
  data, error = Convertible(req.params) |> params_to_data |> to_value_error
  if error !== nothing
    return handle(middleware(BadRequest, APIDataV1(error), JSONData), req, res)
  end

  variable_definition = tax_benefit_system.variable_definition_by_name[data[:variable]]

# {
#         "@type": "Float",
#         "default": 0,
#         "entity": "menages",
#         "formula": {
#             "@type": "SimpleFormula",
#             "comments": null,
#             "doc": "Revenu disponible - ménage\n'men'",
#             "line_number": 103,
#             "module": "openfisca_france.model.mesures",
#             "source": "def function(self, simulation, period):\n    '''\n    Revenu disponible - ménage\n    'men'\n    '''\n    period = period.start.period('year').offset('first-of')\n    rev_trav_holder = simulation.compute('rev_trav', period)\n    pen_holder = simulation.compute('pen', period)\n    rev_cap_holder = simulation.compute('rev_cap', period)\n    psoc_holder = simulation.compute('psoc', period)\n    ppe_holder = simulation.compute('ppe', period)\n    impo = simulation.calculate('impo', period)\n\n    pen = self.sum_by_entity(pen_holder)\n    ppe = self.cast_from_entity_to_role(ppe_holder, role = VOUS)\n    ppe = self.sum_by_entity(ppe)\n    psoc = self.cast_from_entity_to_role(psoc_holder, role = CHEF)\n    psoc = self.sum_by_entity(psoc)\n    rev_cap = self.sum_by_entity(rev_cap_holder)\n    rev_trav = self.sum_by_entity(rev_trav_holder)\n\n    return period, rev_trav + pen + rev_cap + psoc + ppe + impo\n"
#         },
#         "label": "Revenu disponible du ménage",
#         "name": "revdisp",
#         "url": "http://fr.wikipedia.org/wiki/Revenu_disponible"
#     }

  response_data = ["value" => to_json(variable_definition)]
  return handle(middleware(APIDataV1(response_data), JSONData), req, res)
end
