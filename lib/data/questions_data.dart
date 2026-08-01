import '../models/question.dart';

/// The MyPetFit questionnaire — 45 questions across 9 categories.
///
/// Transcribed verbatim from the approved application design (the assessment
/// specification), including per-option scores.
/// Categories 1–8 are scored; category 9 is informational only.
///
/// Question ids are `c<category>q<question>`, 1-based, and answer ids append
/// the option letter — stable keys for persisted answers.
const List<QuestionCategory> healthCategories = [
  // 1 ---------------------------------------------------------------------
  QuestionCategory(
    id: 'skin_coat',
    name: 'Skin & Coat Health',
    questions: [
      Question(
        id: 'c1q1',
        text: "How would you rate the quality of your pet's coat?",
        answers: [
          Answer(id: 'c1q1a', text: 'Hair loss', score: 2),
          Answer(id: 'c1q1b', text: 'Dull or thinning', score: 4),
          Answer(id: 'c1q1c', text: 'Mild shedding', score: 4),
          Answer(id: 'c1q1d', text: 'Shiny and full', score: 8),
        ],
      ),
      Question(
        id: 'c1q2',
        text: 'Any visible skin issues?',
        answers: [
          Answer(id: 'c1q2a', text: 'Infections or rashes', score: 2),
          Answer(id: 'c1q2b', text: 'Itching or allergies', score: 4),
          Answer(id: 'c1q2c', text: 'No issues', score: 8),
        ],
      ),
    ],
  ),

  // 2 ---------------------------------------------------------------------
  QuestionCategory(
    id: 'activity_fitness',
    name: 'Activity & Fitness Level',
    questions: [
      Question(
        id: 'c2q1',
        text: "How would you describe your pet's general daily activity level?",
        answers: [
          Answer(id: 'c2q1a', text: 'Sedentary', score: 2),
          Answer(id: 'c2q1b', text: 'Mildly active', score: 4),
          Answer(id: 'c2q1c', text: 'Active', score: 7),
          Answer(id: 'c2q1d', text: 'Very active', score: 8),
        ],
      ),
      Question(
        id: 'c2q2',
        text: 'How much exercise does your pet get per day on average?',
        answers: [
          Answer(id: 'c2q2a', text: 'Less than 15 minutes', score: 2),
          Answer(id: 'c2q2b', text: '15–30 minutes', score: 4),
          Answer(id: 'c2q2c', text: '30–60 minutes', score: 6),
          Answer(id: 'c2q2d', text: 'More than 1 hour', score: 8),
        ],
      ),
      Question(
        id: 'c2q3',
        text: 'How long can your pet stay in moderate activity before getting '
            'tired?',
        answers: [
          Answer(id: 'c2q3a', text: 'Less than 10 minutes', score: 0),
          Answer(id: 'c2q3b', text: '10–30 minutes', score: 4),
          Answer(id: 'c2q3c', text: '30–60 minutes', score: 8),
          Answer(id: 'c2q3d', text: 'Over 1 hour', score: 10),
        ],
      ),
      Question(
        id: 'c2q4',
        text: 'Does your pet show signs of fatigue or hesitation during '
            'physical activity?',
        answers: [
          Answer(id: 'c2q4a', text: 'Frequently', score: 2),
          Answer(id: 'c2q4b', text: 'Occasionally', score: 4),
          Answer(id: 'c2q4c', text: 'Rarely or never', score: 8),
        ],
      ),
      Question(
        id: 'c2q5',
        text: 'Has your pet ever taken part in agility, obedience or sport '
            'training?',
        answers: [
          Answer(id: 'c2q5a', text: 'Yes', score: 8),
          Answer(id: 'c2q5b', text: 'No', score: 4),
        ],
      ),
      Question(
        id: 'c2q6',
        text: "Has your pet's activity level changed over the past 6 months?",
        answers: [
          Answer(id: 'c2q6a', text: 'Decreased', score: 4),
          Answer(id: 'c2q6b', text: 'No change', score: 6),
          Answer(id: 'c2q6c', text: 'Increased', score: 8),
        ],
      ),
    ],
  ),

  // 3 ---------------------------------------------------------------------
  QuestionCategory(
    id: 'oral_vision_hearing',
    name: 'Oral, Vision & Hearing',
    questions: [
      Question(
        id: 'c3q1',
        text: 'What is the current oral condition of your pet?',
        answers: [
          Answer(id: 'c3q1a', text: 'Bad breath', score: 2),
          Answer(id: 'c3q1b', text: 'Gum disease or tooth loss', score: 5),
          Answer(id: 'c3q1c', text: 'Mild tartar', score: 7),
          Answer(id: 'c3q1d', text: 'Clean teeth', score: 10),
        ],
      ),
      Question(
        id: 'c3q2',
        text: 'Has your pet shown any signs of vision problems?',
        answers: [
          Answer(id: 'c3q2a', text: 'Partial or complete blindness', score: 2),
          Answer(id: 'c3q2b', text: 'Cataracts or cloudiness', score: 4),
          Answer(id: 'c3q2c', text: 'Normal', score: 10),
        ],
      ),
      Question(
        id: 'c3q3',
        text: 'Any signs of hearing decline?',
        answers: [
          Answer(id: 'c3q3a', text: 'Deaf', score: 0),
          Answer(id: 'c3q3b', text: 'Occasionally misses sounds', score: 6),
          Answer(id: 'c3q3c', text: 'Normal', score: 10),
        ],
      ),
    ],
  ),

  // 4 ---------------------------------------------------------------------
  QuestionCategory(
    id: 'behavior_mental',
    name: 'Behavior & Mental Wellness',
    questions: [
      Question(
        id: 'c4q1',
        text: "How would you describe your pet's typical behaviour?",
        answers: [
          Answer(id: 'c4q1a', text: 'Lethargic', score: 0),
          Answer(id: 'c4q1b', text: 'Aggressive', score: 4),
          Answer(id: 'c4q1c', text: 'Anxious', score: 6),
          Answer(id: 'c4q1d', text: 'Calm', score: 10),
        ],
      ),
      Question(
        id: 'c4q2',
        text: 'Any signs of mental confusion, memory loss or disorientation?',
        answers: [
          Answer(id: 'c4q2a', text: 'Frequently disoriented', score: 0),
          Answer(id: 'c4q2b', text: 'Occasionally confused', score: 8),
          Answer(id: 'c4q2c', text: 'Alert', score: 10),
        ],
      ),
      Question(
        id: 'c4q3',
        text: 'Does your pet engage in mentally stimulating activities '
            '(puzzle toys, training, scent games)?',
        answers: [
          Answer(id: 'c4q3a', text: 'Never', score: 0),
          Answer(id: 'c4q3b', text: 'Rarely', score: 2),
          Answer(id: 'c4q3c', text: 'A few times a week', score: 6),
          Answer(id: 'c4q3d', text: 'Daily', score: 10),
        ],
      ),
      Question(
        id: 'c4q4',
        text: 'How often do you introduce new activities, toys or '
            'environments?',
        answers: [
          Answer(id: 'c4q4a', text: 'Never', score: 0),
          Answer(id: 'c4q4b', text: 'Occasionally', score: 4),
          Answer(id: 'c4q4c', text: 'Monthly', score: 8),
          Answer(id: 'c4q4d', text: 'Weekly', score: 10),
        ],
      ),
      Question(
        id: 'c4q5',
        text: 'Does your pet have a companion?',
        answers: [
          Answer(id: 'c4q5a', text: 'Yes', score: 8),
          Answer(id: 'c4q5b', text: 'No', score: 2),
        ],
      ),
      Question(
        id: 'c4q6',
        text: 'Have you noticed boredom or destructive behaviour when left '
            'alone?',
        answers: [
          Answer(id: 'c4q6a', text: 'Yes, frequently', score: 0),
          Answer(id: 'c4q6b', text: 'Occasionally', score: 4),
          Answer(id: 'c4q6c', text: 'Rarely', score: 8),
        ],
      ),
    ],
  ),

  // 5 ---------------------------------------------------------------------
  QuestionCategory(
    id: 'sleep_nutrition',
    name: 'Sleep & Nutrition',
    questions: [
      Question(
        id: 'c5q1',
        text: 'How many hours does your pet sleep per 24 hours?',
        answers: [
          Answer(id: 'c5q1a', text: 'More than 14 hours', score: 2),
          Answer(id: 'c5q1b', text: '10–14 hours', score: 4),
          Answer(id: 'c5q1c', text: 'Less than 10 hours', score: 6),
        ],
      ),
      Question(
        id: 'c5q2',
        text: 'Have you noticed disturbed sleep or restlessness?',
        answers: [
          Answer(id: 'c5q2a', text: 'Yes', score: 2),
          Answer(id: 'c5q2b', text: 'No', score: 4),
        ],
      ),
      Question(
        id: 'c5q3',
        text: 'How many meals does your pet receive per day?',
        answers: [
          Answer(id: 'c5q3a', text: 'Irregular', score: 4),
          Answer(id: 'c5q3b', text: '3 meals', score: 6),
        ],
      ),
      Question(
        id: 'c5q4',
        text: 'What type of food is predominantly provided?',
        answers: [
          Answer(id: 'c5q4a', text: 'Non-prescribed, irregular food', score: 2),
          Answer(id: 'c5q4b', text: 'Prescribed pet food', score: 8),
        ],
      ),
      Question(
        id: 'c5q5',
        text: 'Do you provide any supplements?',
        followLabel: 'Which supplements',
        followHint: 'Minerals (Ca, Mg, Zn, Fe) / Vitamins (A, B, C, D)',
        answers: [
          Answer(id: 'c5q5a', text: 'No supplements', score: 2),
          Answer(id: 'c5q5b', text: 'Occasionally provided', score: 4),
          Answer(id: 'c5q5c', text: 'Daily, regular supplements', score: 8),
        ],
      ),
    ],
  ),

  // 6 ---------------------------------------------------------------------
  QuestionCategory(
    id: 'digestive_urinary',
    name: 'Digestive & Urinary Health',
    questions: [
      Question(
        id: 'c6q1',
        text: 'Is your pet currently on a specialised diet for gut health?',
        answers: [
          Answer(id: 'c6q1a', text: 'No', score: 4),
          Answer(id: 'c6q1b', text: 'Yes — commercial brand', score: 8),
          Answer(id: 'c6q1c', text: 'Yes — veterinary prescribed', score: 10),
        ],
      ),
      Question(
        id: 'c6q2',
        text: 'Do you give any gut-support products?',
        answers: [
          Answer(id: 'c6q2a', text: 'None', score: 2),
          Answer(
            id: 'c6q2b',
            text: 'Fibre supplements (pumpkin, beet pulp, inulin)',
            score: 4,
          ),
          Answer(
            id: 'c6q2c',
            text: 'Digestive enzymes (papain, bromelain)',
            score: 6,
          ),
          Answer(id: 'c6q2d', text: 'Probiotics (curd and similar)', score: 8),
        ],
      ),
      Question(
        id: 'c6q3',
        text: 'Have you noticed gas, bloating or frequent loose stools?',
        answers: [
          Answer(id: 'c6q3a', text: 'Frequently', score: 2),
          Answer(id: 'c6q3b', text: 'Occasionally', score: 4),
          Answer(id: 'c6q3c', text: 'Rarely', score: 6),
          Answer(id: 'c6q3d', text: 'Never', score: 8),
        ],
      ),
      Question(
        id: 'c6q4',
        text: "How would you describe your pet's bowel movements?",
        answers: [
          Answer(id: 'c6q4a', text: 'Blood or mucus present', score: 0),
          Answer(id: 'c6q4b', text: 'Diarrhoea', score: 1),
          Answer(id: 'c6q4c', text: 'Irregular or loose', score: 4),
          Answer(id: 'c6q4d', text: 'Constipation', score: 5),
          Answer(id: 'c6q4e', text: 'Normal', score: 8),
        ],
      ),
      Question(
        id: 'c6q5',
        text: 'Any digestive disorders or diseases diagnosed?',
        answers: [
          Answer(id: 'c6q5a', text: 'Yes', score: 0),
          Answer(id: 'c6q5b', text: 'No', score: 6),
        ],
      ),
      Question(
        id: 'c6q6',
        text: 'How frequently does your pet urinate?',
        answers: [
          Answer(
            id: 'c6q6a',
            text: 'Severe incontinence or accidents',
            score: 0,
          ),
          Answer(id: 'c6q6b', text: 'Reduced', score: 4),
          Answer(id: 'c6q6c', text: 'Increased', score: 4),
          Answer(id: 'c6q6d', text: 'Normal, 3–5 times a day', score: 8),
        ],
      ),
    ],
  ),

  // 7 ---------------------------------------------------------------------
  QuestionCategory(
    id: 'physical_internal',
    name: 'Physical & Internal Health',
    questions: [
      Question(
        id: 'c7q1',
        text: 'How does your pet move during walks or physical activity?',
        answers: [
          Answer(id: 'c7q1a', text: 'Diagnosed arthritis', score: 0),
          Answer(id: 'c7q1b', text: 'Limping', score: 2),
          Answer(id: 'c7q1c', text: 'Mild stiffness', score: 6),
          Answer(id: 'c7q1d', text: 'Moves freely', score: 8),
        ],
      ),
      Question(
        id: 'c7q2',
        text: "How would you describe your pet's current body shape?",
        answers: [
          Answer(id: 'c7q2a', text: 'Obese or heavy', score: 2),
          Answer(id: 'c7q2b', text: 'Slightly overweight', score: 5),
          Answer(id: 'c7q2c', text: 'Ideal and well-proportioned', score: 7),
          Answer(id: 'c7q2d', text: 'Lean and muscular', score: 8),
        ],
      ),
      Question(
        id: 'c7q3',
        text: 'Do you feel your pet is gaining or losing muscle mass?',
        answers: [
          Answer(id: 'c7q3a', text: 'Losing', score: 2),
          Answer(id: 'c7q3b', text: 'Maintaining', score: 4),
          Answer(id: 'c7q3c', text: 'Gaining', score: 8),
        ],
      ),
      Question(
        id: 'c7q4',
        text: 'Any known heart condition diagnosed by a vet?',
        answers: [
          Answer(
            id: 'c7q4a',
            text: 'Confirmed heart condition or disorder',
            score: 0,
          ),
          Answer(id: 'c7q4b', text: 'Mild murmur', score: 6),
          Answer(id: 'c7q4c', text: 'None diagnosed', score: 8),
        ],
      ),
      Question(
        id: 'c7q5',
        text: "How is your pet's breathing under normal conditions?",
        answers: [
          Answer(id: 'c7q5a', text: 'Diagnosed respiratory condition', score: 0),
          Answer(
            id: 'c7q5b',
            text: 'Heavy panting or breathlessness',
            score: 4,
          ),
          Answer(id: 'c7q5c', text: 'Normal', score: 8),
        ],
      ),
      Question(
        id: 'c7q6',
        text: 'Has your pet been tested or diagnosed with liver or kidney '
            'issues?',
        answers: [
          Answer(id: 'c7q6a', text: 'Chronic or diagnosed condition', score: 0),
          Answer(id: 'c7q6b', text: 'Mild enzyme elevation', score: 8),
          Answer(id: 'c7q6c', text: 'No issues', score: 10),
        ],
      ),
    ],
  ),

  // 8 ---------------------------------------------------------------------
  QuestionCategory(
    id: 'medical_lifestyle',
    name: 'Medical & Lifestyle Tracking',
    questions: [
      Question(
        id: 'c8q1',
        text: 'Is your pet fully vaccinated according to age?',
        followLabel: 'Date of last vaccination',
        followHint: 'DD / MM / YYYY',
        answers: [
          Answer(id: 'c8q1a', text: 'Yes', score: 10),
          Answer(id: 'c8q1b', text: 'No', score: 2),
        ],
      ),
      Question(
        id: 'c8q2',
        text: 'Is regular deworming and flea or tick control being followed?',
        followLabel: 'Date of last deworming',
        followHint: 'DD / MM / YYYY',
        answers: [
          Answer(id: 'c8q2a', text: 'Yes', score: 10),
          Answer(id: 'c8q2b', text: 'No', score: 4),
        ],
      ),
      Question(
        id: 'c8q3',
        text: 'Any surgery for a major illness in the past 12 months?',
        answers: [
          Answer(id: 'c8q3a', text: 'Yes', score: 2),
          Answer(id: 'c8q3b', text: 'No', score: 6),
        ],
      ),
      Question(
        id: 'c8q4',
        text: 'Any surgery after an accident in the past 12 months?',
        answers: [
          Answer(
            id: 'c8q4a',
            text: 'Major surgery (head, gastric, internal organs)',
            score: 4,
          ),
          Answer(
            id: 'c8q4b',
            text: 'Minor surgery (limb fractures, wounds)',
            score: 6,
          ),
          Answer(id: 'c8q4c', text: 'None', score: 6),
        ],
      ),
      Question(
        id: 'c8q5',
        text: 'Has your pet mated or been used for breeding before?',
        answers: [
          Answer(id: 'c8q5a', text: 'No', score: 4),
          Answer(id: 'c8q5b', text: 'Yes', score: 6),
          Answer(id: 'c8q5c', text: 'Neutered or spayed', score: 6),
        ],
      ),
      Question(
        id: 'c8q6',
        text: 'Do you use a smart collar or fitness tracker for your pet?',
        followLabel: 'Device name',
        followHint: 'e.g. Fi, Whistle',
        answers: [
          Answer(id: 'c8q6a', text: 'No, but interested', score: 4),
          Answer(id: 'c8q6b', text: 'Yes', score: 8),
        ],
      ),
    ],
  ),

  // 9 — informational only, excluded from the fitness index ---------------
  QuestionCategory(
    id: 'additional_info',
    name: 'Additional Information',
    questions: [
      Question(
        id: 'c9q1',
        text: "Do you track your pet's activity manually (journal or app)?",
        isScored: false,
        answers: [
          Answer(id: 'c9q1a', text: 'Yes', score: 0),
          Answer(id: 'c9q1b', text: 'No', score: 0),
        ],
      ),
      Question(
        id: 'c9q2',
        text: 'Would you be interested in a personalised fitness or wellness '
            'plan?',
        isScored: false,
        answers: [
          Answer(id: 'c9q2a', text: 'Yes', score: 0),
          Answer(id: 'c9q2b', text: 'No', score: 0),
          Answer(id: 'c9q2c', text: 'Maybe', score: 0),
        ],
      ),
      Question(
        id: 'c9q3',
        text: 'What are your top health or fitness concerns? Pick all that '
            'apply.',
        isScored: false,
        isMulti: true,
        answers: [
          Answer(id: 'c9q3a', text: 'Weight management', score: 0),
          Answer(id: 'c9q3b', text: 'Joint mobility', score: 0),
          Answer(id: 'c9q3c', text: 'Stamina and endurance', score: 0),
          Answer(id: 'c9q3d', text: 'Behaviour and focus', score: 0),
          Answer(id: 'c9q3e', text: 'Muscle development', score: 0),
          Answer(id: 'c9q3f', text: 'Ageing and longevity', score: 0),
        ],
      ),
      Question(
        id: 'c9q4',
        text: 'List any medications your pet is currently taking.',
        isScored: false,
        followLabel: 'Medications',
        followHint: 'Name and dose',
        answers: [
          Answer(id: 'c9q4a', text: 'None', score: 0),
          Answer(id: 'c9q4b', text: 'Yes — listed below', score: 0),
        ],
      ),
      Question(
        id: 'c9q5',
        text: 'When was the last veterinary consultation?',
        isScored: false,
        followLabel: 'Date and reason',
        followHint: 'DD / MM / YYYY — reason',
        answers: [
          Answer(id: 'c9q5a', text: 'Within 6 months', score: 0),
          Answer(id: 'c9q5b', text: '6–12 months ago', score: 0),
          Answer(id: 'c9q5c', text: 'Over a year ago', score: 0),
        ],
      ),
    ],
  ),
];

/// Every question across all categories, in order.
final List<Question> allQuestions = [
  for (final c in healthCategories) ...c.questions,
];

/// Lowest and highest totals the scored questions can produce. The design
/// normalises the fitness percentage as `(earned - min) / (max - min) * 100`,
/// so these are derived from the data rather than hard-coded.
final int assessmentMinScore =
    healthCategories.fold(0, (sum, c) => sum + c.minScore);
final int assessmentMaxScore =
    healthCategories.fold(0, (sum, c) => sum + c.maxScore);
