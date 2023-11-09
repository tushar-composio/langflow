import { ReactNode, useContext, useState } from "react";
import { flowManagerContext } from "../../contexts/flowManagerContext";
import NewChatView from "../newChatView";
import TextInputComponent from "../textInputComponent";
import TextOutputComponent from "../textOutputComponent";
import { extractTypeFromLongId, removeCountFromString } from "../../utils/utils";
import AccordionComponent from "../AccordionComponent";
import { Badge } from "../ui/badge";
import ShadTooltip from "../ShadTooltipComponent";
import IconComponent from "../genericIconComponent";
import { Textarea } from "../ui/textarea";
import { NodeDataType } from "../../types/flow";

export default function IOView(): JSX.Element {
  const {inputIds, outputIds,reactFlowInstance,updateNodeFlowData } =
    useContext(flowManagerContext);
  const options = inputIds.concat(outputIds);
  const [selectedView, setSelectedView] = useState<ReactNode>(handleSelectChange(options[0]));
  // if (outputTypes.includes("ChatOutput")) {
  //   return <NewChatView />;
  // }
  function handleSelectChange(selected: string) {
    const type = extractTypeFromLongId(selected);
    return <NewChatView />
    switch (type) {
      case "ChatOutput":
        return <NewChatView />;
        break;
    }
  }

  return (
    <div className="form-modal-iv-box">
      <div className="mr-6 flex h-full w-2/6 flex-col justify-start overflow-auto scrollbar-hide">
        <div className="file-component-arrangement">
          <IconComponent
            name="Variable"
            className=" file-component-variable"
          />
          <span className="file-component-variables-span text-md">
            Inputs
          </span>
        </div>
        {
          inputIds.filter(input=>extractTypeFromLongId(input)!=="ChatInput").map((inputId,index) => {
            const nodeData:NodeDataType = reactFlowInstance?.getNodes().find(node=>node.id===inputId)?.data;
            return (
              <div className="file-component-accordion-div" key={index}>
              <AccordionComponent
                trigger={
                  <div className="file-component-badge-div">
                    <Badge variant="gray" size="md">
                      {inputId}
                    </Badge>
                    <div
                      className="-mb-1"
                      onClick={(event) => {
                        event.stopPropagation();
                      }}
                    >
                    </div>
                  </div>
                }
                key={index}
                keyValue={inputId}
              >
                <div className="file-component-tab-column">
                  <Textarea
                    value={reactFlowInstance?.getNodes().find(node=>node.id===inputId)?.data?.node?.template?.value.value}
                    className="custom-scroll"
                    onChange={(e) => {
                      e.target.value;
                      if(nodeData){
                        nodeData.node!.template["value"].value = e.target.value;
                        updateNodeFlowData(inputId,nodeData);
                      }
                    }}
                    placeholder="Enter text..."
                  ></Textarea>
                </div>
              </AccordionComponent>
            </div>
            )
          })
        }
      </div>
      {selectedView}
    </div>
  );
}
