scoring = require('./scoring')

feedback =
  messages:
    use_a_few_words: "Escolha boas palavras, mas evite frases comuns."
    no_need_for_mixed_chars: "Essa ficou bem complexa, nem precisava ter tantos símbolos, dígitos ou letras em caixa alta."
    uncommon_words_are_better: "Uma dica é escrever as palavras de um jeito incomum."
    straight_rows_of_keys_are_easy: "Letras e números em sequência são bem fáceis de adivinhar."
    short_keyboard_patterns_are_easy: "Ops, melhor evitar padrões do teclado."
    use_longer_keyboard_patterns: "Se for utilizar o layout do teclado como referência, use sequências maiores."
    repeated_chars_are_easy: 'Repetições como "aaa" são bem fáceis de serem descobertas.'
    repeated_patterns_are_easy: 'Repetições como "abcabcabc" são apenas um pouco mais difíceis de adivinhar que "abc".'
    avoid_repeated_chars: "Evite palavras e caracteres repetidos."
    sequences_are_easy: "Sequências como abc ou 6543 são bem fáceis de serem adivinhadas."
    avoid_sequences: "Opa, é melhor evitar o uso de sequências."
    recent_years_are_easy: "Utilizar datas recentes não é muito seguro."
    avoid_recent_years: "Evite utilizar anos recentes."
    avoid_associated_years: "Evite utilizar datas pessoais e de fácil identificação."
    dates_are_easy: "Datas são bem fáceis de serem adivinhadas."
    avoid_associated_dates_and_years: "Evite utilizar datas pessoais e de fácil identificação."
    top10_common_password: "Essa é uma senha muito comum, melhor tentar outra."
    top100_common_password: "Essa é uma senha muito comum, melhor tentar outra."
    very_common_password: "Essa é uma senha muito comum, melhor tentar outra."
    similar_to_common_password: "Essa é uma senha muito comum, melhor tentar outra."
    a_word_is_easy: "Uma palavra por si só é bem fácil de ser adivinhada."
    names_are_easy: "Colocar seu nome ou sobrenome não é muito seguro"
    common_names_are_easy: "Nomes e sobrenomes comuns são fáceis de adivinhar."
    capitalization_doesnt_help: "Utilizar letras maiúsculas não é muito útil!"
    all_uppercase_doesnt_help: "Utilizar todas as letras maiúsculas têm o mesmo nível de dificuldade de utilizar todas minúsculas."
    reverse_doesnt_help: "Palavras invertidas não são mais difíceis de descobrir.",
    substitution_doesnt_help: "Substituições previsíveis como '@' em vez de 'a' não ajudam muito."
    user_dictionary: "Ops, essa senha é muito fácil de ser descoberta. Escolha uma nova!"

  get_feedback: (score, sequence, custom_messages) ->
    @custom_messages = custom_messages

    # starting feedback
    return if sequence.length == 0
      @build_feedback(null, ['use_a_few_words', 'no_need_for_mixed_chars'])

    # no feedback if score is good or great.
    return if score > 2
      @build_feedback()

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = ['uncommon_words_are_better']
    if feedback?
      @build_feedback(feedback.warning, extra_feedback.concat feedback.suggestions)
    else
      @build_feedback(null, extra_feedback)

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        warning = if match.turns == 1
          'straight_rows_of_keys_are_easy'
        else
          'short_keyboard_patterns_are_easy'
        warning: warning
        suggestions: ['use_longer_keyboard_patterns']

      when 'repeat'
        warning = if match.base_token.length == 1
          'repeated_chars_are_easy'
        else
          'repeated_patterns_are_easy'
        warning: warning
        suggestions: ['avoid_repeated_chars']

      when 'sequence'
        warning: 'sequences_are_easy'
        suggestions: ['avoid_sequences']

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: 'recent_years_are_easy'
          suggestions: ['avoid_recent_years', 'avoid_associated_years']

      when 'date'
        warning: 'dates_are_easy'
        suggestions: ['avoid_associated_dates_and_years']

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'user_inputs'
      'user_dictionary'
    else if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          'top10_common_password'
        else if match.rank <= 100
          'top100_common_password'
        else
          'very_common_password'
      else if match.guesses_log10 <= 4
        'similar_to_common_password'
    else if match.dictionary_name == 'english_wikipedia'
      if is_sole_match
        'a_word_is_easy'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        'names_are_easy'
      else
        'common_names_are_easy'

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push 'capitalization_doesnt_help'
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push 'all_uppercase_doesnt_help'

    if match.reversed and match.token.length >= 4
      suggestions.push 'reverse_doesnt_help'
    if match.l33t
      suggestions.push 'substitution_doesnt_help'

    result =
      warning: warning
      suggestions: suggestions
    result

  get_message: (key) ->
    if @custom_messages? and key of @custom_messages
        @custom_messages[key] or ''
    else if @messages[key]?
      @messages[key]
    else
      throw new Error("unknown message: #{key}")

  build_feedback: (warning_key = null, suggestion_keys = []) ->
    suggestions = []
    for suggestion_key in suggestion_keys
      message = @get_message(suggestion_key)
      suggestions.push message if message?
    feedback =
      warning: if warning_key then @get_message(warning_key) else ''
      suggestions: suggestions
    feedback

module.exports = feedback
