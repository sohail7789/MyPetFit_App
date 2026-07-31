import 'package:flutter/material.dart';
import '../models/question.dart';

final List<QuestionCategory> healthCategories = [
  // Category 1: Skin & Coat Health
  QuestionCategory(
    id: 'skin_coat',
    name: 'Skin & Coat Health',
    icon: Icons.pets_rounded,
    questions: [
      Question(
        id: 'q1',
        text: 'How would you rate the quality of your pet\'s coat?',
        answers: [
          Answer(id: 'q1a', text: 'Hair Loss', score: 2),
          Answer(id: 'q1b', text: 'Dull / Thinning', score: 4),
          Answer(id: 'q1c', text: 'Mild Shedding', score: 4),
          Answer(id: 'q1d', text: 'Shiny & Full', score: 8),
        ],
      ),
      Question(
        id: 'q2',
        text: 'Any visible skin issues?',
        answers: [
          Answer(id: 'q2a', text: 'Infections / Rashes', score: 2),
          Answer(id: 'q2b', text: 'Itching / Allergies', score: 4),
          Answer(id: 'q2c', text: 'No Issues', score: 8),
        ],
      ),
    ],
  ),

  // Category 2: Activity & Fitness Level
  QuestionCategory(
    id: 'activity_fitness',
    name: 'Activity & Fitness Level',
    icon: Icons.cruelty_free_rounded,
    questions: [
      Question(
        id: 'q3',
        text:
            'How would you describe your pet\'s general daily activity level?',
        answers: [
          Answer(id: 'q3a', text: 'Sedentary', score: 2),
          Answer(id: 'q3b', text: 'Mildly Active', score: 4),
          Answer(id: 'q3c', text: 'Active', score: 7),
          Answer(id: 'q3d', text: 'Very Active', score: 8),
        ],
      ),
      Question(
        id: 'q4',
        text: 'How much exercise does your pet get per day on average?',
        answers: [
          Answer(id: 'q4a', text: 'Less than 15 minutes', score: 2),
          Answer(id: 'q4b', text: '15\u201330 minutes', score: 4),
          Answer(id: 'q4c', text: '30\u201360 minutes', score: 6),
          Answer(id: 'q4d', text: 'More than 1 hour', score: 8),
        ],
      ),
      Question(
        id: 'q5',
        text:
            'How long can your pet engage in moderate activity before getting tired?',
        answers: [
          Answer(id: 'q5a', text: 'Less than 10 minutes', score: 0),
          Answer(id: 'q5b', text: '10\u201330 minutes', score: 4),
          Answer(id: 'q5c', text: '30\u201360 minutes', score: 8),
          Answer(id: 'q5d', text: 'Over 1 hour', score: 10),
        ],
      ),
      Question(
        id: 'q6',
        text:
            'Does your pet show signs of fatigue or hesitation during physical activity?',
        answers: [
          Answer(id: 'q6a', text: 'Frequently', score: 2),
          Answer(id: 'q6b', text: 'Occasionally', score: 4),
          Answer(id: 'q6c', text: 'Rarely / Never', score: 8),
        ],
      ),
      Question(
        id: 'q7',
        text:
            'Has your pet ever participated in agility, obedience, or sport training?',
        answers: [
          Answer(id: 'q7a', text: 'Yes', score: 8),
          Answer(id: 'q7b', text: 'No', score: 4),
        ],
      ),
    ],
  ),

  // Category 3: Oral, Vision & Hearing
  QuestionCategory(
    id: 'oral_vision_hearing',
    name: 'Oral, Vision & Hearing',
    icon: Icons.emoji_nature_rounded,
    questions: [
      Question(
        id: 'q8',
        text: 'What is the current oral condition of your pet?',
        answers: [
          Answer(id: 'q8a', text: 'Bad Breath', score: 2),
          Answer(id: 'q8b', text: 'Gum Disease or Tooth Loss', score: 5),
          Answer(id: 'q8c', text: 'Mild Tartar', score: 7),
          Answer(id: 'q8d', text: 'Clean Teeth', score: 10),
        ],
      ),
      Question(
        id: 'q9',
        text: 'Has your pet shown any signs of vision problems?',
        answers: [
          Answer(id: 'q9a', text: 'Partial / Complete Blindness', score: 2),
          Answer(id: 'q9b', text: 'Cataracts / Cloudiness', score: 4),
          Answer(id: 'q9c', text: 'Normal', score: 10),
        ],
      ),
      Question(
        id: 'q10',
        text: 'Any signs of hearing decline?',
        answers: [
          Answer(id: 'q10a', text: 'Deaf', score: 0),
          Answer(id: 'q10b', text: 'Occasionally Misses Sounds', score: 6),
          Answer(id: 'q10c', text: 'Normal', score: 10),
        ],
      ),
    ],
  ),

  // Category 4: Behavior & Mental Wellness
  QuestionCategory(
    id: 'behavior_mental',
    name: 'Behavior & Mental Wellness',
    icon: Icons.flutter_dash_rounded,
    questions: [
      Question(
        id: 'q11',
        text: 'How would you describe your pet\'s typical behavior?',
        answers: [
          Answer(id: 'q11a', text: 'Lethargic', score: 0),
          Answer(id: 'q11b', text: 'Aggressive', score: 4),
          Answer(id: 'q11c', text: 'Anxious', score: 6),
          Answer(id: 'q11d', text: 'Calm', score: 10),
        ],
      ),
      Question(
        id: 'q12',
        text:
            'Any signs of mental confusion, memory loss, or disorientation?',
        answers: [
          Answer(id: 'q12a', text: 'Frequently Disoriented', score: 0),
          Answer(id: 'q12b', text: 'Occasionally Confused', score: 8),
          Answer(id: 'q12c', text: 'Alert', score: 10),
        ],
      ),
      Question(
        id: 'q13',
        text:
            'Does your pet engage in mentally stimulating activities (e.g., puzzle toys, training)?',
        answers: [
          Answer(id: 'q13a', text: 'Never', score: 0),
          Answer(id: 'q13b', text: 'Rarely', score: 2),
          Answer(id: 'q13c', text: 'A few times a week', score: 6),
          Answer(id: 'q13d', text: 'Daily', score: 10),
        ],
      ),
      Question(
        id: 'q14',
        text:
            'How often do you introduce new activities, toys, or environments?',
        answers: [
          Answer(id: 'q14a', text: 'Never', score: 0),
          Answer(id: 'q14b', text: 'Occasionally', score: 4),
          Answer(id: 'q14c', text: 'Monthly', score: 8),
          Answer(id: 'q14d', text: 'Weekly', score: 10),
        ],
      ),
      Question(
        id: 'q15',
        text: 'Does your pet have a companion?',
        answers: [
          Answer(id: 'q15a', text: 'Yes', score: 8),
          Answer(id: 'q15b', text: 'No', score: 2),
        ],
      ),
      Question(
        id: 'q16',
        text:
            'Have you noticed signs of boredom or destructive behavior when left alone?',
        answers: [
          Answer(id: 'q16a', text: 'Yes, frequently', score: 0),
          Answer(id: 'q16b', text: 'Occasionally', score: 4),
          Answer(id: 'q16c', text: 'Rarely', score: 8),
        ],
      ),
    ],
  ),

  // Category 5: Sleep & Nutrition
  QuestionCategory(
    id: 'sleep_nutrition',
    name: 'Sleep & Nutrition',
    icon: Icons.egg_rounded,
    questions: [
      Question(
        id: 'q17',
        text: 'How many hours does your pet typically sleep per 24 hours?',
        answers: [
          Answer(id: 'q17a', text: 'More than 14 hours', score: 2),
          Answer(id: 'q17b', text: '10\u201314 hours', score: 4),
          Answer(id: 'q17c', text: 'Less than 10 hours', score: 6),
        ],
      ),
      Question(
        id: 'q18',
        text:
            'Have you noticed any signs of disturbed sleep or restlessness?',
        answers: [
          Answer(id: 'q18a', text: 'Yes', score: 2),
          Answer(id: 'q18b', text: 'No', score: 4),
        ],
      ),
      Question(
        id: 'q19',
        text: 'How many meals does your pet receive per day?',
        answers: [
          Answer(id: 'q19a', text: 'Irregular', score: 4),
          Answer(id: 'q19b', text: '3 Meals', score: 6),
        ],
      ),
      Question(
        id: 'q20',
        text: 'What type of food is predominantly provided?',
        answers: [
          Answer(
              id: 'q20a',
              text: 'Non-Prescribed (irregular food)',
              score: 2),
          Answer(id: 'q20b', text: 'Prescribed (pet food)', score: 8),
        ],
      ),
      Question(
        id: 'q21',
        text: 'Do you provide any supplements?',
        answers: [
          Answer(id: 'q21a', text: 'No supplements', score: 2),
          Answer(id: 'q21b', text: 'Occasionally provided', score: 4),
          Answer(
              id: 'q21c',
              text: 'Provide daily regular supplements',
              score: 8),
        ],
      ),
    ],
  ),

  // Category 6: Digestive Health
  QuestionCategory(
    id: 'digestive_health',
    name: 'Digestive Health',
    icon: Icons.set_meal_rounded,
    questions: [
      Question(
        id: 'q22',
        text: 'Is your pet currently on a specialized diet for gut health?',
        answers: [
          Answer(id: 'q22a', text: 'No', score: 4),
          Answer(id: 'q22b', text: 'Yes \u2013 Commercial brand', score: 8),
          Answer(
              id: 'q22c',
              text: 'Yes \u2013 Veterinary prescribed',
              score: 10),
        ],
      ),
      Question(
        id: 'q23',
        text: 'Do you give any of the following digestive support?',
        answers: [
          Answer(id: 'q23a', text: 'None', score: 2),
          Answer(id: 'q23b', text: 'Fiber supplements', score: 4),
          Answer(id: 'q23c', text: 'Digestive enzymes', score: 6),
          Answer(id: 'q23d', text: 'Probiotics', score: 8),
        ],
      ),
      Question(
        id: 'q24',
        text:
            'Have you noticed symptoms such as gas, bloating, or frequent loose stools?',
        answers: [
          Answer(id: 'q24a', text: 'Frequently', score: 2),
          Answer(id: 'q24b', text: 'Occasionally', score: 4),
          Answer(id: 'q24c', text: 'Rarely', score: 6),
          Answer(id: 'q24d', text: 'Never', score: 8),
        ],
      ),
      Question(
        id: 'q25',
        text: 'How would you describe your pet\'s bowel movements?',
        answers: [
          Answer(id: 'q25a', text: 'Blood / Mucus Present', score: 0),
          Answer(id: 'q25b', text: 'Diarrhea', score: 1),
          Answer(id: 'q25c', text: 'Irregular / Loose', score: 4),
          Answer(id: 'q25d', text: 'Constipation', score: 5),
          Answer(id: 'q25e', text: 'Normal', score: 8),
        ],
      ),
      Question(
        id: 'q26',
        text: 'Any digestive disorders/diseases diagnosed?',
        answers: [
          Answer(id: 'q26a', text: 'Yes', score: 0),
          Answer(id: 'q26b', text: 'No', score: 6),
        ],
      ),
    ],
  ),

  // Category 7: Physical & Internal Health
  QuestionCategory(
    id: 'physical_internal',
    name: 'Physical & Internal Health',
    icon: Icons.monitor_heart_rounded,
    questions: [
      Question(
        id: 'q27',
        text: 'How frequently does your pet urinate?',
        answers: [
          Answer(
              id: 'q27a',
              text: 'Severe incontinence / Accidental urination',
              score: 0),
          Answer(id: 'q27b', text: 'Reduced', score: 4),
          Answer(id: 'q27c', text: 'Increased', score: 4),
          Answer(id: 'q27d', text: 'Normal (3\u20135 times/day)', score: 8),
        ],
      ),
      Question(
        id: 'q28',
        text: 'How does your pet move during walks or physical activity?',
        answers: [
          Answer(id: 'q28a', text: 'Diagnosed Arthritis', score: 0),
          Answer(id: 'q28b', text: 'Limping', score: 2),
          Answer(id: 'q28c', text: 'Mild Stiffness', score: 6),
          Answer(id: 'q28d', text: 'Moves Freely', score: 8),
        ],
      ),
      Question(
        id: 'q29',
        text: 'How would you describe your pet\'s current body shape?',
        answers: [
          Answer(id: 'q29a', text: 'Obese / Heavy', score: 2),
          Answer(id: 'q29b', text: 'Slightly Overweight', score: 5),
          Answer(id: 'q29c', text: 'Ideal / Well-Proportioned', score: 7),
          Answer(id: 'q29d', text: 'Lean / Muscular', score: 8),
        ],
      ),
      Question(
        id: 'q30',
        text: 'Do you feel your pet is gaining or losing muscle mass?',
        answers: [
          Answer(id: 'q30a', text: 'Losing', score: 2),
          Answer(id: 'q30b', text: 'Maintaining', score: 4),
          Answer(id: 'q30c', text: 'Gaining', score: 8),
        ],
      ),
      Question(
        id: 'q31',
        text: 'Any known heart condition diagnosed by a vet?',
        answers: [
          Answer(
              id: 'q31a',
              text: 'Confirmed Heart Condition / Disorder',
              score: 0),
          Answer(id: 'q31b', text: 'Mild Murmur', score: 6),
        ],
      ),
      Question(
        id: 'q32',
        text: 'How is your pet\'s breathing under normal conditions?',
        answers: [
          Answer(
              id: 'q32a',
              text: 'Diagnosed Respiratory Condition',
              score: 0),
          Answer(
              id: 'q32b',
              text: 'Heavy Panting / Breathlessness',
              score: 4),
          Answer(id: 'q32c', text: 'Normal', score: 8),
        ],
      ),
      Question(
        id: 'q33',
        text:
            'Has your pet been tested or diagnosed with liver/kidney issues?',
        answers: [
          Answer(
              id: 'q33a',
              text: 'Chronic Condition / Diagnosed',
              score: 0),
          Answer(id: 'q33b', text: 'Mild Enzyme Elevation', score: 8),
          Answer(id: 'q33c', text: 'No Issues', score: 10),
        ],
      ),
    ],
  ),

  // Category 8: Medical & Lifestyle Tracking
  QuestionCategory(
    id: 'medical_lifestyle',
    name: 'Medical & Lifestyle Tracking',
    icon: Icons.vaccines_rounded,
    questions: [
      Question(
        id: 'q34',
        text: 'Is your pet fully vaccinated according to age?',
        hasTextField: true,
        textFieldLabel: 'Date of Last Vaccination',
        answers: [
          Answer(id: 'q34a', text: 'Yes', score: 10),
          Answer(id: 'q34b', text: 'No', score: 2),
        ],
      ),
      Question(
        id: 'q35',
        text: 'Is regular deworming and flea/tick control being followed?',
        hasTextField: true,
        textFieldLabel: 'Date of Last Deworming',
        answers: [
          Answer(id: 'q35a', text: 'Yes', score: 10),
          Answer(id: 'q35b', text: 'No', score: 4),
        ],
      ),
      Question(
        id: 'q36',
        text:
            'Has your pet had any surgery for major illnesses in the past 12 months?',
        answers: [
          Answer(id: 'q36a', text: 'Yes', score: 2),
          Answer(id: 'q36b', text: 'No', score: 6),
        ],
      ),
      Question(
        id: 'q37',
        text:
            'Has your pet had any surgery for an accident in the past 12 months?',
        answers: [
          Answer(
              id: 'q37a',
              text: 'Major surgery (head, gastric, internal organs)',
              score: 4),
          Answer(
              id: 'q37b',
              text: 'Minor surgery (limb fractures, wounds)',
              score: 6),
        ],
      ),
      Question(
        id: 'q38',
        text: 'Has your pet mated or been used for breeding before?',
        answers: [
          Answer(id: 'q38a', text: 'No', score: 4),
          Answer(id: 'q38b', text: 'Yes', score: 6),
          Answer(id: 'q38c', text: 'Neutered / Spayed', score: 6),
        ],
      ),
      Question(
        id: 'q39',
        text:
            'Has your pet\'s activity level changed over the past 6 months?',
        answers: [
          Answer(id: 'q39a', text: 'Decreased', score: 4),
          Answer(id: 'q39b', text: 'No Change', score: 6),
          Answer(id: 'q39c', text: 'Increased', score: 8),
        ],
      ),
      Question(
        id: 'q40',
        text:
            'Do you currently use a smart collar or fitness tracker for your pet?',
        hasTextField: true,
        textFieldLabel: 'Device Name',
        answers: [
          Answer(id: 'q40a', text: 'No, but interested', score: 4),
          Answer(id: 'q40b', text: 'Yes', score: 8),
        ],
      ),
    ],
  ),

  // Category 9: Additional Information (non-scored)
  QuestionCategory(
    id: 'additional_info',
    name: 'Additional Information',
    icon: Icons.catching_pokemon_rounded,
    questions: [
      Question(
        id: 'q41',
        text:
            'Do you track your pet\'s activity manually (e.g., journal or app)?',
        isScored: false,
        answers: [
          Answer(id: 'q41a', text: 'Yes', score: 0),
          Answer(id: 'q41b', text: 'No', score: 0),
        ],
      ),
      Question(
        id: 'q42',
        text:
            'Would you be interested in a personalized fitness or wellness plan?',
        isScored: false,
        answers: [
          Answer(id: 'q42a', text: 'Yes', score: 0),
          Answer(id: 'q42b', text: 'No', score: 0),
          Answer(id: 'q42c', text: 'Maybe', score: 0),
        ],
      ),
      Question(
        id: 'q43',
        text: 'What are your top health or fitness concerns for your pet?',
        isScored: false,
        answers: [
          Answer(id: 'q43a', text: 'Weight Management', score: 0),
          Answer(id: 'q43b', text: 'Joint Mobility', score: 0),
          Answer(id: 'q43c', text: 'Stamina / Endurance', score: 0),
          Answer(id: 'q43d', text: 'Behavior & Focus', score: 0),
        ],
      ),
      Question(
        id: 'q44',
        text: 'List all medications (if any) your pet is currently taking:',
        isScored: false,
        hasTextField: true,
        textFieldLabel: 'Current medications',
        answers: [
          Answer(id: 'q44a', text: 'Enter below', score: 0),
        ],
      ),
      Question(
        id: 'q45',
        text: 'When was the last veterinary consultation?',
        isScored: false,
        hasTextField: true,
        textFieldLabel: 'Date and reason',
        answers: [
          Answer(id: 'q45a', text: 'Enter below', score: 0),
        ],
      ),
    ],
  ),
];
