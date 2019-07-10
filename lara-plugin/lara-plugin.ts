import iframePhone from "iframe-phone"

declare const ace: any;

interface Tutorial {
  $forEachExercise: (callback: (el: any) => void) => void;
  $exerciseEditor: (label: string) => any;
}

interface ExcerciseMap {
  [key: string]: string;
}

interface TutorialState {
  version: 1,
  exercises: ExcerciseMap
}

interface InitInteractiveData {
  interactiveState: string | null;
}

interface AceEditor {
  getSession: () => {
    getValue: () => string;
  },
  setValue: (value: string, cursorPos: number) => void;
}

interface InitOptions {
  laraIntegration: boolean;
  tutorial: Tutorial;
}

export const init = (options: InitOptions) => {

  const phone = iframePhone.getIFrameEndpoint();

  if (options.laraIntegration) {
    phone.addListener("initInteractive", (data: InitInteractiveData) => {
      if (data.interactiveState) {
        try {
          const state: TutorialState = JSON.parse(data.interactiveState);
          if ((state.version === 1) && state.exercises) {
            setState(options.tutorial, state);
          }
        }
        catch (e) {}
      }
    });
    phone.addListener("getInteractiveState", () => {
      phone.post("interactiveState", JSON.stringify(getState(options.tutorial)));
    });
  }

  phone.initialize();
  phone.post("supportedFeatures", {
    apiVersion: 1,
    features: {
      interactiveState: options.laraIntegration,
      // aspectRatio: TODO
    }
  });
}

const forEachExercise = (tutorial: Tutorial, callback: (label: string, editor: AceEditor | null) => void) => {
  tutorial.$forEachExercise(($el) => {
    const label = $el.attr("data-label");
    const editorContainer = tutorial.$exerciseEditor(label);
    const editor = editorContainer.length > 0 ? ace.edit(editorContainer.attr("id")) : null;
    callback(label, editor);
  });
}

const getState = (tutorial: Tutorial) => {
  const state: TutorialState = {
    version: 1,
    exercises: {}
  };
  forEachExercise(tutorial, (label, editor) => {
    state.exercises[label] = editor ? editor.getSession().getValue() : "";
  });
  return state;
};

const setState = (tutorial: Tutorial, state: TutorialState) => {
  forEachExercise(tutorial, (label, editor) => {
    if (state.exercises[label] && editor) {
      editor.setValue(state.exercises[label], -1);
    }
  });
};
