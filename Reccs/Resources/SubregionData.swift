//
//  SubregionData.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/10/26.
//

import Foundation

let SubregionNames: [String: String] = [
    "AFNO": "North Africa", "AFNE": "Northeast Africa", "AFEA": "East Africa",
    "AFSO": "Southern Africa", "AFCE": "Central Africa", "AFWE": "West Africa",
    "AFNC": "North-Central Africa", "AMNO": "Northern North America", "AMEA": "Eastern North America",
    "AMSW": "Southwest North America", "AMNW": "Northwest North America", "AMIN": "Interior North America",
    "AMCE": "Central America", "AMCR": "Caribbean", "AMWE": "Western South America",
    "AMNE": "Northeast South America", "AMSO": "Southern South America", "ASNO": "North Asia",
    "ASIN": "Inner Asia", "ASEA": "East Asia", "ASHI": "Highland Asia",
    "ASSE": "Southeast Asia", "ASSO": "South Asia", "ASSW": "Southwest Asia",
    "ASWE": "West Asia", "ASCE": "Central Asia", "EUEA": "Eastern Europe",
    "EUWE": "Western Europe", "OCAU": "Australia", "OCMD": "Madagascar",
    "OCMR": "Maritime Southeast Asia", "OCML": "Melanesia", "OCMC": "Micronesia",
    "OCPL": "Polynesia",
    "PORTAL_WEST": "", "PORTAL_EAST": ""
]

let SubregionDescriptions: [String: String] = [
    "AFNO": "The Amazigh languages themselves—in addition to their persistence, with Coptic, as substrata on regional Arabic dialects—anchor the distinctive linguistic and cultural heritage of the Maghreb and outer Sahara.",
    "AFNE": "The Cushitic, Omotic, and Semitic languages, all part of the broader Afroasiatic language family, are spoken across the Horn of Africa.",
    "AFEA": "This subregion is made up of the Nilotic eastern Sudanian belt, the Bantu Swahili Coast, and the Hadza and Sandawe areas of the southeast.",
    "AFSO": "Khoisan Southern Africa includes speakers of the click consonant Kxʼa, Taa–ǃKwi, and Khoe–Kwadi language families in the Karoo, Kalahari Basin, and Okavango Delta, in addition to click-borrowing Bantu groups like the Nguni.",
    "AFCE": "Mbenga, Mbuti, and Twa groups in the Congo Basin speak the Bantu, Ubangian, and Central Sudanic languages of the surrounding areas, with some specialized botanical vocabulary of earlier origin.",
    "AFWE": "Comprised of Upper and Lower Guinea (separated by the Dahomey Gap) and the western Sudanian savanna, this subregion is dominated by the western branches of the Niger–Congo language family.",
    "AFNC": "From the Tibesti Mountains in the north to the Lake Chad Basin in the south, the Chadic and Saharan languages extend across the oases found in the central Sahara and Sahel.",
    "AMNO": "The Eskaleut languages encircle the Arctic from Greenland to Alaska and extend across the Behring Strait to the Chukchi Peninsula, and are distinct from older Algic and Na-Dené parts of the Subarctic also in this subregion.",
    "AMEA": "Coterminous with the Eastern Woodlands, this subregion accounts for the cultural areas of the Northeastern and Southeastern Woodlands and the Great Lakes, including language families like the Algonquian, Iroquoian, and Muskogean.",
    "AMSW": "Encompassing the American Southwest, Great Basin, and Californian cultural areas, where the Uto-Aztecan and Hokan families, alongside prominent isolates like Zuni and Washoe or outliers like Diné Bizaad, are spoken.",
    "AMNW": "The Pacific Northwest Coast and Plateau cultural areas are largely defined by the diversity of Salishan, Penutian, Wakashan, Tsimshianic, and Chimakuan languages spread across the coast and interior.",
    "AMIN": "The Interior Plains include the Great Plains, Prairies, and Rockies, where the Caddoan, Western Siouan, and Plains Algonquian language families are spoken.",
    "AMCE": "Mesoamerica—the Nahua and Oto-Manguean spheres of influence in the west and the Mayan world in the east—as well as the transitional Isthmo-Colombian area’s Chibchan and Misumalpan languages, constitute this subregion.",
    "AMCR": "This subregion includes the Arawakan Taíno languages of the Greater Antilles, and the more-recently introduced Cariban languages of the Lesser Antilles, alongside older languages like Guanahatabey, Macorix, and Ciguayo.",
    "AMWE": "The Andean Region is dominated by the imperial Quechuan and Aymaran languages, alongside families like the Chibchan and Barbacoan in the north, across the terrains of the Costeña, Cordillera, and eastern foothills.",
    "AMNE": "The Guiana Shield, Orinoquia, Amazonia, and the Brazilian Plateau can all be found within this subregion, where the Macro-Jê, Tupian, Arawakan, Cariban, and Panoan languages, among others, are spoken.",
    "AMSO": "The Southern Cone consists of Patagonia, the Pampas, the Southern Andes, and Tierra del Fuego, and includes language families like Araucanian and Guaicuruan, and the Chon and Puelche-Het of the Fuegian sprachbund.",
    "ASNO": "Siberia, its peninsulas from the Yamal to the Kamchatka and islands like Sakhalin and Hokkaido, contains speakers of Uralic and Tungusic languages and older families like Chukotko–Kamchatkan, Nivkh, Yeniseian, and Yukaghir.",
    "ASIN": "The cultural and linguistic domains of the Mongolic and southern Tungusic peoples extend across the eastern Eurasian Steppe and Manchuria in this subregion.",
    "ASEA": "The Sinitic, Koreanic, and Japonic languages form the core of this sphere of cultural interchange surrounding the East China Sea.",
    "ASHI": "This subregion is characterized by the Tibetic sphere of influence pervading the Qinghai-Tibetan Plateau and the Himalayas, including the central Ü-Tsang, eastern Kham, and northeastern Amdo regional groupings.",
    "ASSE": "Austroasiatic, Kra–Dai, Hmong–Mien, and Sino–Tibetan languages converge in the Indochinese sprachbund, divided up into river valleys by the numerous mountain ranges of Mainland Southeast Asia.",
    "ASSO": "The Dravidian languages dominate the southern Deccan peninsula, whereas Indo-Aryan languages extend across the northern Ganga and Indus plains, the Thar desert, and the northeastern mountain zone.",
    "ASSW": "Resting south of the Caspian Sea, the Iranian Plateau runs from the Zagros Mountains in the west to the Sulaiman Mountains in the east, populated by speakers of Iranic languages and their neighbors in the southeast Caucasus.",
    "ASWE": "The Arabian Peninsula, Mesopotamia, and the Levant are populated by speakers of the predominant Semitic languages in this subregion.",
    "ASCE": "The central Eurasian Steppe, stretching from the Ural mountains in the west to the Altai mountains in the east, is predominantly a diverse mix of Turkic and Iranic cultures.",
    "EUEA": "This subregion is dominated by Balto-Slavic and Uralic languages and the Balkan sprachbund; its plains of the western Eurasian Steppe are bordered by the Carpathian, Ural, and Caucasus mountain ranges to the west, east, and south.",
    "EUWE": "This subregion includes the Latin, Germanic, and Celtic cultural areas, in various admixtures, and the branches of the Indo-European language families of the same names.",
    "OCAU": "The Pama–Nyungan language family, of which three-quarters of all Australian languages are part, covers nearly 90% of the continent, while the remaining ~30 families and isolates are clustered in the north.",
    "OCMD": "A combination of Austronesian (originating in Maritime Southeast Asia) and later Bantu (via Southeast Africa) influences converge to constitute the Malagasy language and culture predominant across the island.",
    "OCMR": "The Austronesian languages of the Malaysphere pervade throughout this subregion, while older isolates and substrata persist in some secluded archipelagos and rugged island interiors.",
    "OCML": "There are 1,000–1,500 distinct languages spoken in Melanesia, as much as one-quarter of the global total, centered on New Guinea and the surrounding islands.",
    "OCMC": "Austronesian languages of the Oceanic branch, featuring extensive maritime vocabulary, pervade throughout this subregion in a unique synthesis of Melanesian and Polynesian influences.",
    "OCPL": "Speakers of the closely related Polynesian languages of the Oceanic branch of Austronesian span the vast expanse of ocean covered by the Polynesian Triangle."
]
