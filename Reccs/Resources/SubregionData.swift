//
//  SubregionData.swift
//  Reccs
//
//  Created by Evan Gedrich Pintado on 3/10/26.
//

import Foundation

let SubregionNames: [String: String] = [
    "AFNO": "North Africa", "AFEA": "East Africa", "AFSO": "Southern Africa",
    "AFCE": "Central Africa", "AFWE": "West Africa", "AMNO": "Northern North America",
    "AMEA": "Eastern North America", "AMSW": "Southwest North America", "AMNW": "Northwest North America",
    "AMIN": "Interior North America", "AMCE": "Central America", "AMCR": "Caribbean",
    "AMHI": "Western South America", "AMLO": "Northeast South America", "AMSO": "Southern South America",
    "ASNO": "North Asia", "ASEA": "East Asia", "ASSE": "Southeast Asia",
    "ASHI": "Highland Asia", "ASSO": "South Asia", "ASWE": "West Asia",
    "ASCE": "Central Asia", "ASIN": "Inner Asia", "EUEA": "Eastern Europe",
    "EUWE": "Western Europe", "OCAU": "Australia", "OCMD": "Madagascar",
    "OCML": "Melanesia", "OCMC": "Micronesia", "OCPL": "Polynesia",
    "PORTAL_WEST": "", "PORTAL_EAST": ""
]

let SubregionDescriptions: [String: String] = [
    "AFNO": "The Amazigh languages anchor the distinctive linguistic and cultural heritage of the Maghreb, Sahara, and Sahel.",
    "AFEA": "This subregion includes the Cushitic Horn of Africa, the Nilotic eastern Sudanian belt, the Bantu Swahili Coast, and the Hadza and Sandawe areas of the southeast.",
    "AFSO": "Khoisan Southern Africa includes speakers of the click consonant Kxʼa, Taa–ǃKwi, and Khoe–Kwadi language families in the Karoo, Kalahari Basin, and Okavango Delta, in addition to click-borrowing Bantu groups like the Nguni.",
    "AFCE": "Mbenga, Mbuti, and Twa groups in the Congo Basin speak the Bantu, Ubangian, and Central Sudanic languages of the surrounding areas, with some specialized botanical vocabulary of earlier origin.",
    "AFWE": "Comprised of Upper and Lower Guinea (separated by the Dahomey Gap) and the western Sudanian savanna, this subregion is dominated by the western branches of the Niger–Congo language family.",
    "AMNO": "The Eskaleut languages encircle the Arctic from Greenland to Alaska and extend across the Behring Strait to the Chukchi Peninsula, and are distinct from older Algic and Na-Dené parts of the Subarctic also in this subregion.",
    "AMEA": "Coterminous with the Eastern Woodlands, this subregion accounts for the cultural areas of the Northeastern and Southeastern Woodlands and the Great Lakes, including language families like the Algonquian, Iroquoian, and Muskogean.",
    "AMSW": "Encompassing the American Southwest, Great Basin, and Californian cultural areas, where the Uto-Aztecan and Hokan families, alongside prominent isolates like Zuni and Washoe or outliers like Diné Bizaad, are spoken.",
    "AMNW": "The Pacific Northwest Coast and Plateau cultural areas are largely defined by the diversity of Salishan, Penutian, Wakashan, Tsimshianic, and Chimakuan languages spread across the coast and interior.",
    "AMIN": "The Interior Plains include the Great Plains, Prairies, and Rockies, where the Siouan, Caddoan, and Plains Algonquian language families are spoken.",
    "AMCE": "Mesoamerica—the Nahua and Oto-Manguean spheres of influence in the east and the Mayan world in the west—as well as the transitional Isthmo-Colombian area's Chibchan and Misumalpan languages, constitute this subregion.",
    "AMCR": "This subregion includes the Arawakan Taíno languages of the Greater Antilles, and the more-recently introduced Cariban languages of the Lesser Antilles, alongside older languages like Guanahatabey, Macorix, and Ciguayo.",
    "AMHI": "The Andean Region is dominated by the imperial Quechuan and Aymaran languages, alongside families like the Chibchan and Barbacoan in the north, across the terrains of the Costeña, Cordillera, and eastern foothills.",
    "AMLO": "The Guiana Shield, Orinoquia, Amazonia, and the Brazilian Plateau can all be found within this subregion, where the Macro-Jê, Tupian, Arawakan, Cariban, and Panoan languages, among others, are spoken.",
    "AMSO": "The Southern Cone consists of Patagonia, the Pampas, the Southern Andes, and Tierra del Fuego, and includes language families like Araucanian and Guaicuruan, and the Chon and Puelche-Het of the Fuegian sprachbund.",
    "ASNO": "Siberia, its peninsulas from the Yamal to the Kamchatka and islands like Sakhalin and Hokkaido, contains speakers of Uralic and Tungusic languages and older families like Chukotko–Kamchatkan, Nivkh, Yeniseian, and Yukaghir.",
    "ASEA": "The Sinitic, Koreanic, and Japonic languages form the core of this sphere of cultural interchange surrounding the East China Sea.",
    "ASSE": "Southeast Asia is most clearly divided into its Mainland and Maritime components, where Austroasiatic, Kra–Dai, and Sino–Tibetan areas dominate the Indochinese sprachbund in the former, and Austronesian languages extend throughout the Malaysphere in the latter.",
    "ASHI": "This subregion is characterized by the Tibetic sphere of influence pervading the Qinghai-Tibetan Plateau and the Himalayas, including the central Ü-Tsang, eastern Kham, and northeastern Amdo regional groupings.",
    "ASSO": "The Dravidian languages in the south, as well as the Indo-Aryan languages of the Indus-Gangetic Plain in the north and Iranian-influenced northwest, comprise the major linguistic and cultural areas of this subregion.",
    "ASWE": "The Arabian Peninsula, Iranian Plateau, and Anatolia comprise the Arabic, Persic, and Turkic spheres of this subregion, in addition to transitional areas like Mesopotamia, Sinai, and the Armenian Highlands.",
    "ASCE": "The central Eurasian Steppe, stretching from the Ural mountains in the west to the Altai mountains in the east, is predominantly a diverse mix of Turkic and Iranic cultures.",
    "ASIN": "The cultural and linguistic domains of the Mongolic and southern Tungusic peoples extend across the eastern Eurasian Steppe and Manchuria in this subregion.",
    "EUEA": "This subregion is dominated by the Balto-Slavic and Uralic language families and the Balkan sprachbund; its extensive plains are bordered by the Carpathian, Ural, and Caucasus mountain ranges to the west, east, and south.",
    "EUWE": "This subregion includes the Latin, Germanic, and Celtic cultural areas, in various admixtures, and the branches of the Indo-European language families of the same names.",
    "OCAU": "The Pama–Nyungan language family, of which three-quarters of all Australian languages are part, covers nearly 90% of the continent, while the remaining ~30 families and isolates are clustered in the north.",
    "OCMD": "A combination of Austronesian (originating in Maritime Southeast Asia) and later Bantu (via Southeast Africa) influences converge to constitute the Malagasy language and culture predominant across the island.",
    "OCML": "There are 1,000–1,500 distinct languages spoken in Melanesia, as much as one-quarter of the global total, centered on New Guinea and the surrounding islands.",
    "OCMC": "Austronesian languages of the Oceanic branch, featuring extensive maritime vocabulary, pervade throughout this subregion in a unique synthesis of Melanesian and Polynesian influences.",
    "OCPL": "Speakers of the closely related Polynesian languages of the Oceanic branch of Austronesian span the vast expanse of ocean covered by the Polynesian Triangle."
]
