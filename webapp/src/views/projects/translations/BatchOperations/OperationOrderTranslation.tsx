
import { useProject } from 'tg.hooks/useProject';
import { User } from 'tg.component/UserAccount';

import { OperationProps } from './types';
import { BatchOperationsSubmit } from './components/BatchOperationsSubmit';
import { OperationContainer } from './components/OperationContainer';
import { useTranslationsSelector } from '../context/TranslationsContext';
import { getPreselectedLanguagesIds } from './getPreselectedLanguages';
import { useBranchFromUrlPath } from 'tg.component/branching/useBranchFromUrlPath';

type Props = OperationProps;

export const OperationOrderTranslation = ({ disabled, onFinished }: Props) => {
  const project = useProject();
  const branch = useBranchFromUrlPath();

  const allLanguages = useTranslationsSelector((c) => c.languages) ?? [];
  const selection = useTranslationsSelector((c) => c.selection);
  const translationsLanguages = useTranslationsSelector(
    (c) => c.translationsLanguages
  );

  const languageAssignees = {} as Record<number, User[]>;
  const selectedLanguages = getPreselectedLanguagesIds(
    allLanguages.filter((l) => !l.base),
    translationsLanguages ?? []
  );

  selectedLanguages.forEach((langId) => {
    languageAssignees[langId] = [];
  });

  return (
    <OperationContainer>
      <BatchOperationsSubmit
        disabled={disabled}
        onClick={() => {}}
      />
      <></>
    </OperationContainer>
  );
};
