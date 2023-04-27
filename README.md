# Event Extraction from Natural Language Text with OpenAI's API

Demonstration of using OpenAI's pre-trained LLMs for the linguistic annotation task of event extraction.

## Demo

The following recording shows a demonstration:

[![asciicast](https://asciinema.org/a/71mNIyHcH2TpiMTtQG1ET8TyN.svg)](https://asciinema.org/a/71mNIyHcH2TpiMTtQG1ET8TyN)

## Setup

### Install `shell-gpt`

Make a virtual Python environment:

```zsh
$ python3 -m venv events
...
$ source events/bin/activate
(events) $ pip3 install -U pip
...
(events) $ pip3 install -r requirements.txt
...
```

### Setup OpenAI API Access

You will need an OpenAI API key.

If you don't have an account with OpenAI's platform, sign up here: https://platform.openai.com/

After creating an account, set up a payment method.

You'll need to set up an API key here: https://platform.openai.com/account/api-keys

Use the "Create new secret key" button to generate an API key to associate with shell-gpt.

### Configure `shell-gpt`

Once you've obtained an API key for use with shell-gpt, follow the instructions [here](https://github.com/TheR1D/shell_gpt/blob/main/README.md#installation) to set an `$OPENAI_API_KEY` environment variable.

You can alternatively follow the prompt to configure `~/.config/shell_gpt/.sgptrc`).

If you set up your `.sgptrc` it should look something like this:

```
OPENAI_API_KEY={secret OpenAI API key string (it should start with "sk-")}
OPENAI_API_HOST=https://api.openai.com
CHAT_CACHE_LENGTH=100
CHAT_CACHE_PATH={temp directory path}
CACHE_LENGTH=100
CACHE_PATH={temp directory path}
REQUEST_TIMEOUT=60
DEFAULT_MODEL=gpt-4
DEFAULT_COLOR=magenta
ROLE_STORAGE_PATH={path to role directory like $HOME/.config/shell_gpt/roles}
SYSTEM_ROLES=false
```

### Copy the Role Configuration JSON

Copy the preconfigured role JSON to your configured `ROLE_STORAGE_PATH` directory:

```zsh
(events) $ cp roles/events_analyzer.json ~/.config/shell_gpt/roles/
```

You should see the role now when you run `sgpt --list-roles`:

```zsh
(events) $ sgpt --list-roles
~/.config/shell_gpt/roles/default.json
~/.config/shell_gpt/roles/shell.json
~/.config/shell_gpt/roles/code.json
...
~/.config/shell_gpt/roles/events_analyzer.json
(events)
$ sgpt --show-role events_analyzer
I want you to perform an information extraction task involving natural language processing.  I will provide you text, and I want to extract the events that are mentioned in the text, as well as the participating entities within each event instance.

The input will be structured with one component being natural language text, with the goal being that entity mentions and event mentions will be annotated with identifiers that are unique within the text.  The input will also include a list of event frames that are of interest to be analyzed.

An example of the input format is as follows:

```json
{
  "text": "Two news reporters were fired on Monday.  Don Lemon was fired by CNN after 17 years.  Fox News also ousted Tucker Carlson who had been with the network since 2009.",
  "frames": [
    {
      "type": "Firing_1",
      "description": "An [employer] ends an employment relationship with an [employee] from a [position].  There may also be a [reason] that motivates the firing and the firing may occur on some specified [date]."
    }
  ]
}
```

Only emit JSON as output without any other textual descriptions.
```

You can also inspect the expected output format that has been configured for this role with:

```zsh
(events) $ jq .expecting ~/.config/shell_gpt/roles/events_analyzer.json | jq -r .
{
  "annotations": "Two news [reporters|T1] were [fired|E1] on [Monday|T2].  [Don Lemon|T3] was [fired|E2] by [CNN|T4] after 17 [years|T5].  [Fox News|T6] also [ousted|E3] [Tucker Carlson|T7] [who|T8] had been with the [network|T9] since [2009|T10].",
  "events": [
    {
      "type": "Firing_1",
      "trigger": {
        "id": "E1",
        "text": "fired"
      },
      "roles": [
        {
          "employee": {
            "id": "T1",
            "text": "reporters"
          },
          "date": {
            "id": "T2",
            "text": "Monday"
          }
        }
      ]
    },
    {
      "type": "Firing_1",
      "trigger": {
        "id": "E2",
        "text": "fired"
      },
      "roles": [
        {
          "employee": {
            "id": "T3",
            "text": "Don Lemon"
          }
        },
        {
          "employer": {
            "id": "T4",
            "text": "CNN"
          }
        },
        {
          "date": {
            "id": "T5",
            "text": "years"
          }
        }
      ]
    },
    {
      "type": "Firing_1",
      "trigger": {
        "id": "E3",
        "text": "ousted"
      },
      "roles": [
        {
          "employee": {
            "id": "T7",
            "text": "Tucker Carlson"
          }
        },
        {
          "employer": {
            "id": "T6",
            "text": "Fox News"
          }
        },
        {
          "date": {
            "id": "T10",
            "text": "2009"
          }
        }
      ]
    }
  ]
}
```

## Peform Analysis

For this section we'll assume you have [`jq`](https://stedolan.github.io/jq/) to inspect various JSON data, and we'll assume you're using `bash`, `ksh`, or `zsh` (or another shell with support for [here strings](https://en.wikipedia.org/wiki/Here_document#Here_strings)).

Once you've set everything up, you can analyze an input.  As an example, we'll take the input in the included `datasets/data.jsonl`:

To analyze some text with specific event frames, we formulate our input like so:

```json
{
  "text": str,
  "frames": [
    {
      "type": str,
      "description": str
    }
  ]
}
```

Let's look at some example input JSONs:

```zsh
(events) $ jq . datasets/data.jsonl 
{
  "text": "Two news reporters were fired on Monday.  Don Lemon was fired by CNN after 17 years.  Fox News also ousted Tucker Carlson who had been with the network since 2009.",
  "frames": [
    {
      "type": "Firing_1",
      "description": "An [employer] ends an employment relationship with an [employee] from a [position].  There may also be a [reason] that motivates the firing and the firing may occur on some specified [date]."
    }
  ]
}
{
  "text": "A group of workers were fired from Acme Fund at the end of the day on Friday.  The group included Alice, Bob, and Cindy, who were each terminated for violating insider trading laws.  Dylan was not ousted, for now.",
  "frames": [
    {
      "type": "Firing_1",
      "description": "An [employer] ends an employment relationship with an [employee] from a [position].  There may also be a [reason] that motivates the firing and the firing may occur on some specified [date]."
    }
  ]
}
{
  "text": "Debbie and her team attended the Wednesday stakeholder meeting.  They ended up agreeing to procure a new espresso machine for $2,000.",
  "frames": [
    {
      "type": "Purchase_1",
      "description": "An [buyer] exchanges [money] with a [seller] in return for [goods].  The purchase may occur on a specified [date] or [place]."
    },
    {
      "type": "Meeting_1",
      "description": "More than one [participant] attends an event planned on a particulare [date].  There may particular [topic]s discussed.  The meeting may occur at a specified [place]."
    }
  ]
}
```

Note that the event frame descriptions are styled similarly to the [FrameNet project](https://framenet.icsi.berkeley.edu/fndrupal/).

Let's extract the second input and analyze it using the configured `events_analyzer` role:

```zsh
(events) $ data="$(tail -n +2 datasets/data.jsonl | head -1)"
(events) $ jq . <<< "$data"
{
  "text": "A group of workers were fired from Acme Fund at the end of the day on Friday.  The group included Alice, Bob, and Cindy, who were each terminated for violating insider trading laws.  Dylan was not ousted, for now.",
  "frames": [
    {
      "type": "Firing_1",
      "description": "An [employer] ends an employment relationship with an [employee] from a [position].  There may also be a [reason] that motivates the firing and the firing may occur on some specified [date]."
    }
  ]
}
(events) $ sgpt --role events_analyzer <<< "$data"
{
  "annotations": "A group of [workers|T1] were [fired|E1] from [Acme Fund|T2] at the end of the day on [Friday|T3].  The group included [Alice|T4], [Bob|T5], and [Cindy|T6], who were each terminated for violating [insider trading laws|T7].  [Dylan|T8] was not [ousted|E2], for now.",
  "events": [
    {
      "type": "Firing_1",
      "trigger": {
        "id": "E1",
... # this may take some time as Open AI's API streams the predicted tokens to your shell (it should be colored magenta if you are writing to `/dev/stdout`)
```

Note that `sgpt` will cache your results by default, so you can quickly get the analysis for the same input by re-running the command.  If you want to save the analysis, redirect it like so:

```zsh
(events) $ sgpt --role events_analyzer <<< "$data" | jq -c . > firing_1-annotation.jsonl
(events) $ jq . firing_1-annotation.jsonl 
{
  "annotations": "A group of [workers|T1] were [fired|E1] from [Acme Fund|T2] at the end of the day on [Friday|T3].  The group included [Alice|T4], [Bob|T5], and [Cindy|T6], who were each terminated for violating [insider trading laws|T7].  [Dylan|T8] was not [ousted|E2], for now.",
  "events": [
    {
      "type": "Firing_1",
      "trigger": {
        "id": "E1",
        "text": "fired"
      },
      "roles": [
        {
          "employee": {
            "id": "T1",
            "text": "workers"
          },
          "employer": {
            "id": "T2",
            "text": "Acme Fund"
          },
          "date": {
            "id": "T3",
            "text": "Friday"
          }
        },
        {
          "employee": {
            "id": "T4",
            "text": "Alice"
          },
          "reason": {
            "id": "T7",
            "text": "insider trading laws"
          }
        },
        {
          "employee": {
            "id": "T5",
            "text": "Bob"
          },
          "reason": {
            "id": "T7",
            "text": "insider trading laws"
          }
        },
        {
          "employee": {
            "id": "T6",
            "text": "Cindy"
          },
          "reason": {
            "id": "T7",
            "text": "insider trading laws"
          }
        }
      ]
    },
...
```

If you don't cache the results, you may get a different analyses as OpenAI's models are not deterministic (the randomness can be adjusted to a degree using `sgpt`'s `--temperature` option—see the [OpenAI API documentation](https://platform.openai.com/docs/api-reference/completions/create#completions/create-temperature)).

You can get uncached results with the `sgpt`'s `--no-cache` option.

### Analyze Multiple Inputs

To analyze multiple inputs, iteratively, you can use the provided `analyze.zsh` script.

The script will read JSON lines from a file, analyze each one, and write JSON lines with the analyses to `/dev/stdout`.

```
# analyze each input in `data.jsonl` with the gpt-4 model
(events) $ ./analyze.zsh datasets/data.jsonl gpt-4 > annotations.jsonl
... # it may take a while to run analysis on all the inputs
(events) $ jq . annotations.jsonl
...
   {
      "type": "Traveling_1",
      "trigger": {
        "id": "E2",
        "text": "leaving"
      },
      "roles": [
        {
          "traveler": {
            "id": "T1",
            "text": "Jack"
          }
        },
        {
          "traveler": {
            "id": "T2",
            "text": "Jill"
          }
        },
        {
          "origin": {
            "id": "T5",
            "text": "Springfield"
          }
        }
      ]
    }
  ]
}
```
