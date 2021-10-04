
 --SELECT id,
 --data #>>'{repCollection,0,value,resp_rep_name}' AS resp_rep_name, 
 --data #>>'{repCollection,0,value,name_of_organisation}' AS name_of_organisation, 
 --data #>>'{repCollection,0,value,name_of_representative}' AS name_of_representative, 
 --data #>>'{repCollection,0,value,representative_address,PostCode}' AS PostCode, 
 --data #>>'{repCollection,0,value,representative_address,AddressLine1}' AS AddressLine1, 
 --data #>>'{repCollection,0,value,representative_phone_number}' AS representative_phone_number, 
 --data #>>'{repCollection,0,value,representative_email_address}' AS representative_email_address
 --from case_data ;
 
  
--resp_rep_name
UPDATE case_data SET data = jsonb_set(data, '{repCollection,0,value,resp_rep_name}', to_jsonb(translate(data #>>'{repCollection,0,value,resp_rep_name}', 'abcoefghijk123','zat')), FALSE) WHERE data#>> '{repCollection,0,value,resp_rep_name}' IS NOT NULL ;

-- name_of_organisation
 UPDATE case_data SET data = jsonb_set(data, '{repCollection,0,value,name_of_organisation}', to_jsonb(translate(data #>>'{repCollection,0,value,name_of_organisation}', 'abcdefghijk123','bfa')), FALSE) WHERE data#>> '{repCollection,0,value,name_of_organisation}' IS NOT NULL;
 
-- name_of_representative
UPDATE case_data SET data = jsonb_set(data, '{repCollection,0,value,name_of_representative}', to_jsonb(translate(data #>>'{repCollection,0,value,name_of_representative}', 'acdefohimn123','kdq')), FALSE) WHERE data#>> '{repCollection,0,value,name_of_representative}' IS NOT NULL;

-- AddressLine1
UPDATE case_data SET data = jsonb_set(data, '{repCollection,0,value,representative_address,AddressLine1}', to_jsonb(translate(data #>>'{repCollection,0,value,representative_address,AddressLine1}', 'defohin123','cmz')), FALSE) WHERE data #>>'{repCollection,0,value,representative_address,AddressLine1}' IS NOT NULL;

---- postcode 
  UPDATE case_data SET  data =  jsonb_set(data,'{repCollection,0,value,representative_address,PostCode}',to_jsonb(random_postcode(array['NG34 0RN', 'TN24 8DB', 'WD3 1BU', 'LA6 2SL', 'WD6 4HT', 'LA1 4ER', 'RM13 9RY', 'TQ4 5BD', 'EN4 8FS', 'RG18 9EU', 'WV5 0LQ', 'LL61 6RE', 'SA10 9HN', 'B68 9SR', 'YO32 9TQ', 'NW8 8SY', 'DL6 3DG', 'LS16 5AQ', 'AL10 9GW', 'SW17 0PR', 'YO32 3EJ', 'BT23 7XR', 'G84 7RT', 'DL7 0AQ', 'WA15 7RS', 'W9 2AN', 'DL1 1RA', 'L13 7EH', 'B74 2PH', 'N4 2PY', 'EX10 0NX', 'BB5 5SH', 'ML6 8XB', 'SY23 3JU', 'SY3 9FW', 'TQ5 9QS', 'IP11 9HW', 'DA12 2AZ', 'CH7 2DA', 'B10 0HX', 'HP5 1QP', 'FK17 8AZ', 'TS3 8DB', 'SK11 7BZ', 'HD9 6BH', 'PR4 5YD', 'EX7 9QJ', 'SW19 7PS', 'PE28 9QN', 'EX22 7BT', 'NW3 6BX', 'KY10 2FB', 'RG30 3HR', 'TS10 1LS', 'CF14 3AB', 'G64 1LQ', 'EH48 2PZ', 'EX2 9DS', 'DT7 3AW', 'WA7 5SS', 'CH60 8NW', 'BT65 4AW', 'PE26 1AH', 'IP19 8QP', 'CH3 9QU', 'BT42 4HT', 'HU15 1TP', 'BH25 6SP', 'LE4 0RT', 'DT9 4RL', 'TA21 8QF', 'ME1 1FL', 'S66 9QW', 'LE2 4SH', 'NN14 2YZ', 'SN3 2BW', 'AB53 4QL', 'M30 9PE', 'OX2 0NL', 'LS6 4EP', 'BS23 4JY', 'SY1 4EE', 'EH48 2GT', 'GU34 5NB', 'PA75 6QR', 'M8 4HS', 'BS22 6HT', 'SY3 0AT', 'M45 7SS', 'TS7 0QP', 'SP2 7EN', 'KA1 2HG', 'GL18 1TY', 'NW9 5PR', 'LA10 5DQ', 'CT12 6QQ', 'YO25 9ET', 'GU11 1AJ', 'CF5 4GJ', 'CF64 4DQ', 'SK10 9PH', 'CH66 1HH', 'NR9 4HG', 'PO12 1HW', 'CO10 0WW', 'OL5 0PP', 'S9 2TE', 'OX10 0BL', 'BT48 6RU', 'AB12 4NY', 'S40 4HR', 'NP20 5DT', 'GL16 7BN', 'S2 3EX', 'NP44 3DJ', 'TR8 4EZ', 'WA10 3BQ', 'EX20 2AR', 'IP4 5EA', 'BB9 5JT', 'SE9 1PJ', 'LN4 1EN', 'CF5 4GT', 'MK42 0UJ', 'S40 3DQ', 'M9 7BX', 'PR1 8NR', 'TQ12 3RF', 'WV99 1NN', 'DL7 0RP', 'AB15 4AH', 'CV22 7FS', 'CB21 4TR', 'S61 3QW', 'TN2 4XP', 'NG22 9SU', 'SG8 0PE', 'GU14 7AZ', 'SW11 6DF', 'TQ3 1AE', 'LE67 8LU', 'CT4 7BP', 'SE26 4RL', 'TA6 3TW', 'DG2 9QH', 'HG3 2DN', 'RG8 7LL', 'LS88 8BL', 'BT71 7ES', 'E11 3EA', 'HP21 8RZ', 'FK7 7QR', 'SE27 9BB', 'SY8 1HU', 'MK7 8QD', 'RG22 5HG', 'BD3 7HR', 'ME10 1NY', 'BB12 9BL', 'BB5 6HE', 'TN18 4AF', 'WC2E 9FE', 'UB6 8TT', 'LN1 2PD', 'BR6 7NS', 'DH7 9WA', 'CH66 3PJ', 'SA63 4TL', 'TN11 8LZ', 'TQ9 5RH', 'CR0 9JN', 'IV3 8TQ', 'PL13 2PW', 'G20 6ND', 'BS48 2FB', 'PO35 5XJ', 'FK1 5BL', 'SP10 3RH', 'NN5 6SR', 'LS12 1DN', 'IP22 1HW', 'BA6 9TR', 'LS21 2PS', 'PO9 1EF', 'TR20 8BE', 'N9 8HB', 'B32 4LA', 'LE1 1TR', 'KT14 6HB', 'LS13 1PA', 'SR4 9QP', 'CF32 8YS', 'CF72 8EH', 'DT1 1PJ', 'PO14 1AH', 'ME14 9ZZ', 'PL17 7TA', 'CB11 3DL', 'G32 7UA', 'BT16 2GD', 'HA4 0PE', 'SE16 6RX', 'ML3 6NA', 'IP33 2SY', 'TS18 3JJ', 'OX44 9AG', 'WA9 1PJ', 'NN3 7QP', 'TR3 7LJ', 'PR8 9FX', 'EC3M 1EB', 'DG10 9JP', 'OX28 5LW', 'SR7 8HP', 'GL15 6JN', 'SO19 9HY', 'WV13 1HU', 'SK16 5EW', 'B32 2SL', 'LN5 0PP', 'GL51 0BE', 'M5 4PF', 'BL9 7QL', 'IG3 8LH', 'RH2 0AR', 'BT40 2QE', 'PE20 1SP', 'M5 3LS', 'BS13 7HN', 'LE16 8LG', 'DN15 8QJ', 'CO10 7FJ', 'NE71 6HP', 'DH8 9DY', 'N19 4JN', 'DY5 4BY', 'SA63 4TY', 'KY16 0HF', 'WV6 8UU', 'SO51 8PB', 'BB2 5JB', 'TN24 8PB', 'TD15 2QY', 'BL1 5JB', 'HU17 9QU', 'IG11 9DD', 'SN10 4PS', 'CV34 4HH', 'GU15 4AY', 'DE13 0DY', 'DA13 0RG', 'DT10 1HJ', 'M30 0SS', 'SA1 5HN', 'WF13 3BD', 'BA13 3LJ', 'DT7 3EJ', 'TS3 7AQ', 'BA14 8DT', 'TA7 0JB', 'NP7 9YB', 'TS18 5NH', 'CR2 0PZ', 'EX16 6NS', 'PA18 6BD', 'S44 5RP', 'TF2 6SF', 'FY3 9PW', 'DE72 3LP', 'PE2 5LD', 'LS12 6NY', 'PR25 5AH', 'TR16 6BH', 'ML6 8FT', 'DG2 9DB', 'HU9 3RQ', 'S75 4EL', 'LU4 0NF', 'SY11 4PP', 'AL1 5TD', 'IV26 2XG', 'WA8 0ZB', 'CW5 8BZ', 'WF11 0DF', 'SS9 4JG', 'BT61 8NG', 'PR1 4RB', 'CB6 2HY', 'EH47 8AX', 'CM1 6UT', 'BT30 7LJ', 'RG6 6JH', 'IP7 7EZ', 'BS16 1BY', 'N1 1QW', 'YO19 6HJ', 'EH16 6XJ', 'CF10 4LJ', 'CV21 4NF', 'TF1 5EG', 'NW8 0SF', 'SW17 9RR', 'N4 2NU', 'NW10 7FF', 'SW17 9AY', 'SW18 2SU', 'SW12 9SL', 'SE12 0QA', 'W3 9LT', 'SE1 5SH', 'SW4 8JN', 'SW9 6XB', 'SW11 3LF', 'SW12 9RP', 'SW19 1BJ', 'N1 8HW', 'W4 4JY', 'N4 1SB', 'NW7 1AR', 'W6 0TB', 'N8 8AS', 'SW12 9PU', 'N17 9PS', 'E17 6NA', 'SW95 9DP', 'NW4 2SU', 'SW3 2PR', 'SW11 3TW', 'E5 9AZ', 'SE17 1HW', 'W2 4XB', 'W14 0NP', 'NW11 9LE', 'W9 1QY', 'N17 0TW', 'SE13 7HF', 'E17 9LQ', 'W3 6YH', 'SW11 2FT', 'SW15 1NH', 'SW13 9HT', 'E17 6BH', 'E15 4EL', 'N8 0EE', 'NW1 3TE', 'W3 9QF', 'N7 0QT', 'NW6 5BS', 'W5 2DD', 'N12 7HA', 'N17 6BP', 'W14 8EQ', 'NW6 6RD', 'N22 5AS', 'SW12 8EF', 'NW6 7RX', 'SW13 8HD', 'E9 7BA', 'W12 7QW', 'SW7 9BE', 'N16 5EF', 'E1 2EY', 'SW17 7EQ', 'SE12 8DP', 'SW11 5HX', 'SE17 3HH', 'N12 9EP', 'SE16 7NB', 'NW4 4BQ', 'W3 8QD', 'W8 5JB', 'SE11 4EA', 'SW17 0DL', 'NW3 4HN', 'SW5 9SG', 'E2 7HJ', 'E1 3HN', 'E12 5BT', 'E17 5JL', 'E17 4SN', 'W4 2DZ', 'SW12 9NS', 'W3 0EE', 'E3 4QB', 'N17 0JB', 'W5 1UL', 'N17 7PA', 'SW18 9TE', 'E17 5AL', 'W13 9SX', 'SE1 7GS', 'SW19 4AA', 'SW17 1DZ', 'SE25 4QR', 'N14 7JZ', 'SW3 5TX', 'NW9 5XW', 'W11 9FS', 'N21 3JA', 'E3 2HW', 'E18 2JZ', 'SE7 8FF', 'N15 6JT', 'E5 0DQ', 'W11 2DF', 'NW4 1NF', 'E2 7JP', 'SE3 0UJ', 'E8 3SU', 'W8 4RZ', 'N7 9DH', 'W5 3NE', 'SE3 0NS', 'E11 1BY', 'N11 3GP', 'SE3 9AN', 'N2 0FZ', 'E13 0ES', 'NW10 4UQ', 'SE11 6RD', 'SE16 5HH', 'E15 2JL', 'E17 9QE', 'SE19 2AF', 'N14 5LT', 'E17 8YT', 'NW3 5TL', 'NW10 0UJ', 'SW4 7LA', 'N14 4HL', 'N15 4FS', 'SE1 3BY', 'W13 0FE', 'SW16 1JU', 'E11 3DU', 'NW5 4EA', 'E4 8PN', 'N20 0DA', 'W4 4HE', 'N17 0JQ', 'SE3 0SN', 'N6 5YN', 'SW11 1JA', 'SW17 1FX', 'SW9 9JQ', 'SW2 2AE', 'SW5 0DJ', 'N16 8RY', 'SE1 7GF', 'SE18 1RF', 'SE5 7EZ', 'W7 3QZ', 'SE5 8JF', 'SW15 6BS', 'SE1 0QN', 'E17 5SP', 'E18 1PG', 'W4 1PW', 'SE18 3RD', 'N4 3AR', 'SW5 9DA', 'N4 9JE', 'SE1 0SW', 'E11 3EF', 'SW14 8PU', 'SW14 8QY', 'SW6 2LT', 'SE26 4EX', 'E7 9PU', 'E2 7EJ', 'W6 7PZ', 'NW1 6QE', 'N11 2PH', 'NW3 7AJ', 'E2 9DW', 'W8 4HN', 'SE9 6NW', 'E98 1NS', 'SW6 4UE', 'SW5 9PE', 'E1 5EF', 'N1 2JS', 'N9 9TS', 'SW16 5HD', 'SE18 5SJ', 'SE20 8QF', 'NW10 6DE', 'W4 1RZ', 'SW9 6PH', 'NW3 6BH', 'SW18 5JN', 'N13 5JJ', 'W13 8DJ', 'NW1 2SD', 'E18 9BW', 'N9 8RB', 'N19 5DA', 'N9 7DU', 'NW4 4ER', 'N9 0RP', 'SE3 9AB', 'NW1 5HF', 'N2 9JL', 'NW2 3LS', 'NW8 6AD', 'W9 2DX', 'NW10 1SD', 'SW3 5QH', 'SE3 7EF', 'SW7 1HJ', 'W10 5AZ', 'N10 2AL', 'N11 1DT', 'SW6 2PQ', 'N1 7FW', 'SE10 9UH', 'SW17 8EQ', 'SW16 5DY', 'N11 2QH', 'SW5 9JA', 'SW10 9LB', 'NW7 2SB', 'SW4 8BJ', 'NW1 7TS', 'E14 5SP', 'W2 6JE', 'SE19 1UY', 'W2 1ET', 'W7 1XB', 'SE22 8QZ', 'N5 2NJ', 'SE14 5EA', 'E3 3GP', 'SE18 9PH', 'SW19 3UF', 'SE28 0FP', 'SE1 3SZ', 'E1 4LR', 'N1 5EQ', 'SW11 5SX', 'E3 5AR', 'N8 8RE', 'N16 6AS', 'NW1 3EY', 'NW9 5BF', 'N10 3SX', 'SW2 3TR', 'W14 0PH', 'SE1 3QR', 'N20 0JE', 'W13 0SG', 'NW10 2ND', 'NW8 8AZ', 'NW8 9AW', 'N9 9XX', 'E4 8NH', 'N4 2DQ', 'W14 8XJ', 'SW7 2HQ', 'SW8 1HD', 'E2 8EZ', 'NW10 5NX', 'SW13 8HA', 'N21 2NG', 'SW7 2AG', 'E17 4PB', 'W5 2SB', 'N1 9RW', 'SW17 7QY', 'SE28 0PD', 'N3 1HN', 'E1 4EY', 'NW1 0LD', 'SE24 9LZ', 'SW10 9RJ', 'SW3 2AT', 'N10 2EH', 'N12 0EY', 'E4 6TD', 'E3 5HP', 'SE15 5UF', 'W3 7PX', 'SE9 4PS', 'SE15 5UG', 'SE14 6NJ', 'NW1 1WX', 'NW1 3QD', 'SW12 8TG', 'NW10 0NA', 'N1 8QS', 'E1 8EE', 'W8 6LA', 'SW18 2ND', 'W11 3EE', 'NW3 2PL', 'E5 0NP', 'SW9 8EN', 'W12 8ET', 'NW9 9BU', 'E3 3RN', 'SW18 2LH', 'SW11 2AR', 'NW3 6JX', 'SW3 6BD', 'N19 4BS', 'E3 4GJ', 'E3 3GU', 'SW16 9JS', 'SW2 4PA', 'W12 9AY', 'NW9 9QY', 'E6 5QA', 'NW2 4PG', 'SW7 4XJ', 'E11 2EJ', 'N7 0EF', 'NW7 2SH', 'W3 6HD', 'SE5 5SH', 'SW8 2SN', 'SE12 9HD', 'E4 8BJ', 'E2 6QL', 'E4 7NH', 'SW17 7SQ', 'NW1 9LQ', 'SE20 8LA', 'SE1 6JP', 'W13 9ST', 'E9 7SL', 'SE9 1LG', 'NW2 1NR', 'N4 2AH', 'N9 9RT', 'SE5 8JT', 'W10 6AA', 'E8 3PL', 'E5 0AR', 'NW10 5YA', 'E14 8EA', 'SE20 7BP', 'NW9 5DW', 'SW9 8JP', 'NW11 6TR', 'NW7 0AN', 'SW16 1QR', 'NW3 3LR', 'SE1 5QU', 'SW18 9SB', 'SW13 0HQ', 'SW11 4AR', 'SW16 3DR', 'W13 9PS', 'W12 9HD', 'NW1 1JE', 'SE18 1QD', 'SW18 1JL', 'NW3 4DG', 'SE26 5GD', 'N11 3NF', 'N5 2TX', 'SW9 6AB', 'N10 2BH', 'E20 1GS', 'SE3 7TL', 'W12 7EZ', 'E6 3RS', 'N11 2QW', 'E12 6NH', 'W5 2JG', 'SE21 8HN', 'SE1 9BA', 'SE7 7LW', 'SE11 4RD', 'NW10 3JD', 'SE12 0TG', 'E17 7AP', 'SW11 4AS', 'E2 7HG', 'N6 5QU', 'E16 9ED', 'E9 7DD', 'SW16 1RT', 'N1 0TB', 'SE16 7UA', 'SE1 0EY', 'SE26 4SE', 'SW11 4NZ', 'E1 6BD', 'E6 6AS', 'SE28 0LL', 'SW15 3PD', 'E17 3EZ', 'SW7 2ST', 'SE23 3NW', 'SE10 9TE', 'N2 0PZ', 'W12 8JU', 'NW3 4XJ', 'NW6 2JX', 'SE1 2HD', 'NW6 4RN', 'SE5 8HH', 'SE9 1BZ', 'W14 8HU', 'E8 3GF', 'SE9 5EN', 'N13 5ST', 'SE16 3TL', 'SE4 1NZ', 'W4 5HT', 'W5 1RS', 'SW11 4QA', 'E6 3QQ', 'W3 7RE', 'E17 3HY', 'N20 0LE', 'SW4 0HF', 'NW1 7TN', 'NW11 7BT', 'SW3 1PY', 'SW9 6DW', 'E7 0JB', 'SE14 5PH', 'SE20 7UT', 'N13 6JB', 'SW18 2QX', 'W3 9QB', 'SW6 2RE', 'W5 9HN', 'SE18 2EX', 'SW16 6EG', 'E1 4SH', 'SE4 2QB', 'N16 0TR', 'W13 8JE', 'E2 9AR', 'SW4 6BU', 'SE6 4SG', 'SW4 9PL', 'NW3 5LX', 'E4 9ND', 'E1 5RF', 'SW13 0LA', 'W10 6UF', 'SW11 8LZ', 'E1 2NJ', 'NW6 6DU', 'W12 0LR', 'W8 9SX', 'W11 1TU', 'SW4 6DP', 'SW8 3LQ', 'E10 5GH', 'SE1 8TX', 'W14 8SR', 'SW3 4NP', 'E3 5BF', 'SW9 9HZ', 'NW10 7UY', 'N22 5AH', 'N22 5PS', 'SE17 2BH', 'NW10 4QX', 'W2 2JQ', 'SE6 2TG', 'SW15 3PR', 'SE18 7HR', 'E17 4LZ', 'SW12 8SF', 'SE24 9BW', 'N7 9UW', 'SE22 8ET', 'SE13 7EH', 'SE9 6JB', 'W13 9YB', 'SE16 3YA', 'SE2 0LE', 'SE26 6TY', 'E11 3DJ', 'SE28 8RH', 'N21 3HD', 'NW1 4AU', 'SE14 6LE', 'NW8 0JN', 'E2 7SJ', 'NW4 4NB', 'SE3 7JU', 'NW9 9DT', 'SW9 8QF', 'E5 9ST', 'N19 4AG', 'N16 9BA', 'SW20 0EL', 'E2 8AA', 'N22 8PF', 'NW10 0AW', 'N16 0HL', 'E17 6HZ', 'SW16 2TH'])), FALSE) WHERE data #>>'{repCollection,0,value,representative_address,PostCode}' IS NOT NULL;
 
-- phone_number
UPDATE case_data SET data = jsonb_set(data, '{repCollection,0,value,representative_phone_number}', to_jsonb(random_phone_number()), FALSE) WHERE data #>>'{repCollection,0,value,representative_phone_number}' IS NOT NULL;

-- representative_mobile_number
UPDATE case_data SET data = jsonb_set(data, '{repCollection,0,value,representative_mobile_number}', to_jsonb(random_phone_number()), FALSE) WHERE data #>>'{repCollection,0,value,representative_mobile_number}' IS NOT NULL ;

-- representative_email_address
UPDATE case_data SET data = jsonb_set(data, '{repCollection,0,value,representative_email_address}', to_jsonb(translate(data #>>'{repCollection,0,value,representative_email_address}', 'abefhilj123','zcp')), FALSE) WHERE data #>>'{repCollection,0,value,representative_email_address}' IS NOT NULL;
